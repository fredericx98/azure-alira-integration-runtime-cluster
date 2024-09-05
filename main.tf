
provider "azurerm" {
  features {}
  subscription_id = "7251a908-4032-4426-bff1-4201c5a4e690"
}

# Red virtual
resource "azurerm_virtual_network" "integrationruntime_vnet" {
  name                = var.virtualNetworks_integrationruntime_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
}

# Subredes
resource "azurerm_subnet" "pls_subnet" {
  name                 = "pls-subnet"
  resource_group_name  = azurerm_virtual_network.integrationruntime_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.integrationruntime_vnet.name
  address_prefixes     = [var.pls_subnet]
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_virtual_network.integrationruntime_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.integrationruntime_vnet.name
  address_prefixes     = [var.frontend_subnet]
}

resource "azurerm_subnet" "backend_subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_virtual_network.integrationruntime_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.integrationruntime_vnet.name
  address_prefixes     = [var.backend_subnet]
}

# Interfaz de red
resource "azurerm_network_interface" "integrationruntime_backend_nic" {
  name                = "integrationruntime-backend-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Máquina virtual Linux con la interfaz de red
resource "azurerm_linux_virtual_machine" "integrationruntime_backend_vm" {
  name                = "integrationruntime-backend"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2s" # Standard_B12ms tiene mejor networking
  admin_username      = var.linux_user
  admin_password      = var.linux_password
  network_interface_ids = [azurerm_network_interface.integrationruntime_backend_nic.id]
  disable_password_authentication = false 
  custom_data = filebase64("scripts/userdata.sh") 

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "22.04.202408300"
  }
}

# Balanceador de carga
resource "azurerm_lb" "azurerm_lb_integrationruntime" {
  name                = var.load_balancer_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                         = "frontend"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.frontend_subnet.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "integrationruntime_backend" {
  loadbalancer_id = azurerm_lb.azurerm_lb_integrationruntime.id
  name            = "backend"
  
}

resource "azurerm_network_interface_backend_address_pool_association" "backend" {
  network_interface_id    = azurerm_network_interface.integrationruntime_backend_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.integrationruntime_backend.id
}

# Probe (separado del azurerm_lb)
resource "azurerm_lb_probe" "integrationruntime_probe" {
  loadbalancer_id    = azurerm_lb.azurerm_lb_integrationruntime.id
  name               = "health"
  protocol           = "Tcp"
  port               = 22
  interval_in_seconds = 60
  number_of_probes    = 1
}

# Regla de balanceo de carga (separado del azurerm_lb)
resource "azurerm_lb_rule" "rds_dev_rule" {
  name                          = "rds-dev"
  loadbalancer_id               = azurerm_lb.azurerm_lb_integrationruntime.id
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.integrationruntime_backend.id]
  probe_id                      = azurerm_lb_probe.integrationruntime_probe.id
  protocol                      = "Tcp"
  frontend_port                 = 5432
  backend_port                  = 5432
  idle_timeout_in_minutes        = 15
  enable_floating_ip             = false
  disable_outbound_snat          = true
}

#Private Link Service - Falla al crear el servicio
resource "azurerm_private_link_service" "psl" {
  name                = "psl"
  location            = var.location
  resource_group_name = var.resource_group_name

  auto_approval_subscription_ids              = [var.subscription_id]
  visibility_subscription_ids                 = [var.subscription_id]
  
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.azurerm_lb_integrationruntime.frontend_ip_configuration[0].id]

  nat_ip_configuration {
    name                         = "nat-ip-config"
    subnet_id                    = azurerm_subnet.pls_subnet.id
    primary = true
  }

  enable_proxy_protocol = false
}

# resource "azurerm_private_endpoint" "private_endpoint" {
#   name                = "integrationruntime-vnet-private-endpoint"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   subnet_id           = azurerm_subnet.pls_subnet.id

#   private_service_connection {
#     name                        = "private-service-connection"
#     private_connection_resource_id = azurerm_private_link_service.psl.id
#     is_manual_connection = false
    
#   }
# }

resource "azurerm_data_factory_linked_service_postgresql" "aws_rds_development" {
  name                = "AWS_RDS_development"
  data_factory_id     = var.data_factory_id
  integration_runtime_name = var.integration_runtime_name
  

  connection_string = <<-EOF
    Host=AWS_RDS_development;Port=5432;Database=postgres;UID=root;Password=dfdfdfdfdfdfdf
  EOF
}

# resource "azurerm_private_dns_zone" "integrationruntime_vnet" {
#   name                = "privatelink.postgres.database.azure.com" # Ajusta según tu servicio
#   resource_group_name = var.resource_group_name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "link" {
#   name                  = "integrationruntime-vnet-private-dns-link"
#   resource_group_name   = var.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.integrationruntime_vnet.name
#   virtual_network_id    = azurerm_virtual_network.integrationruntime_vnet.id
#   registration_enabled  = true
# }

# resource "azurerm_private_dns_a_record" "example" {
#   name                = var.aws_rds_development_dns
#   zone_name           = azurerm_private_dns_zone.integrationruntime_vnet.name
#   resource_group_name = var.resource_group_name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.private_endpoint.private_service_connection[0].private_ip_address]
# }

