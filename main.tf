
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

resource "azurerm_public_ip" "integrationruntime_backend_public_ip" {
  name                = "integrationruntime-backend-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static" # Cambiado a estático
  sku                 = "Standard" # Asume que estás usando IPs públicas Standard SKU
}


resource "azurerm_network_interface" "integrationruntime_backend_nic" {
  name                = "integrationruntime-backend-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.integrationruntime_backend_public_ip.id
  }
}


# Máquina virtual Linux con la interfaz de red
resource "azurerm_linux_virtual_machine" "integrationruntime_backend_vm" {
  name                = "integrationruntime-backend"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B12ms" #Standard_B2s" # Standard_B12ms tiene mejor networking
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
  protocol                      = "All"
  frontend_port                 = 0
  backend_port                  = 0
  idle_timeout_in_minutes        = 15
  enable_floating_ip             = false
  disable_outbound_snat          = true
}

#Private Link Service - Falla al crear el servicio
resource "azurerm_private_link_service" "psl" {
  name                = "psl"
  location            = var.location
  resource_group_name = var.resource_group_name

  # auto_approval_subscription_ids              = [var.subscription_id]
  # visibility_subscription_ids                 = [var.subscription_id]
  
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.azurerm_lb_integrationruntime.frontend_ip_configuration[0].id]

  nat_ip_configuration {
    name                         = "nat-ip-config"
    subnet_id                    = azurerm_subnet.pls_subnet.id
    primary = true
  }

  enable_proxy_protocol = false
}



### Seguridad

# resource "azurerm_key_vault" "aws_rds_bplaybet_dev" {
#   name                = "aws-rds-bplaybet-dev-kv"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name            = "standard"

#   # Configuración de red: Solo accesible a través de endpoints privados
#   network_acls {
#     default_action             = "Deny"
#     bypass                     = "AzureServices" # Permite solo servicios de confianza como ADF
#     virtual_network_subnet_ids = [var.adf_subnet_vnet]  # Subred de la Managed VNet de Data Factory
#   }
# }


# resource "azurerm_key_vault_access_policy" "aws_rds_bplaybet_dev" {
#   key_vault_id = azurerm_key_vault.aws_rds_bplaybet_dev.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = var.data_factory_object_id

#   secret_permissions = [
#     "Get",
#     "List",
#     "Set",
#     "Delete",
#     "Recover",
#     "Backup",
#     "Restore",
#     "Purge"
#   ]
# }

# resource "azurerm_data_factory_linked_service_key_vault" "aws_rds_bplaybet_dev" {
#   name                = "aws_rds_bplaybet_dev"
#   data_factory_id     = var.data_factory_id

#   key_vault_id = azurerm_key_vault.aws_rds_bplaybet_dev.id
# }

# resource "azurerm_data_factory_linked_service_postgresql" "aws_rds_development_bookmaker" {
#   name                     = "aws_rds_development_bookmaker"
#   data_factory_id          = var.data_factory_id
#   integration_runtime_name = var.integration_runtime_name

#   connection_string = "Hostname=aws-rds-bplaybet.aws.com;Port=5432;Database=bookmaker;Username=root;Password=pepe"
# }
