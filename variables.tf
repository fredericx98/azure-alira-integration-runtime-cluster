
data "azurerm_client_config" "current" {}

variable "location" {
  default = "East US 2"
  type    = string
}

variable "subscription_id" {
  default = "7251a908-4032-4426-bff1-4201c5a4e690"
  type    = string
}

variable "data_factory_id" {
  default = "/subscriptions/7251a908-4032-4426-bff1-4201c5a4e690/resourceGroups/BOLDTAZ-PROD-EastUS2-RG-Data-Analytics/providers/Microsoft.DataFactory/factories/BOLDTAZ-PRD-EastUS2-DataFactory"
  type    = string
}

variable "address_space" {
  default = "172.30.30.0/24"
  type    = string
}

variable "pls_subnet" {
  default = "172.30.30.0/26"
  type    = string
}

variable "frontend_subnet" {
  default = "172.30.30.64/26"
  type    = string
}

variable "backend_subnet" {
  default = "172.30.30.128/26"
  type    = string
}

variable "resource_group_name" {
  default = "BOLDTAZ-PROD-EastUS2-RG-Data-Analytics"
  type    = string
}

variable "virtualNetworks_integrationruntime_vnet_name" {
  default = "integrationruntime-for-vnet"
  type    = string
}

variable "routeTables_forwarding_externalid" {
  default = "/subscriptions/7251a908-4032-4426-bff1-4201c5a4e690/resourceGroups/BOLDTAZ-PROD-EastUS2-RG-Data-Analytics/providers/Microsoft.Network/routeTables/forwarding"
  type    = string
}

variable "linux_user" {
  default = "ubuntu"
  type    = string
}

variable "linux_password" {
  default = "Tecnalis1234$"
  type    = string
}

variable "load_balancer_name" {
  default = "integrationruntime-vnet"
  type = string
}

variable "aws_rds_development_dns" {
  default = "boldt-bplay-bplaybet-development-db.cbklflzdkbbe.us-east-1.rds.amazonaws.com"
  type = string
}

variable "integration_runtime_name" {
  default = "integrationRuntimeVNET"
  type = string
}

variable "data_factory_object_id" {
  default = "c0cf894a-9d12-48ae-a6e4-15ae47d5057e"
  type    = string
}

variable "adf_subnet_vnet" {
  default ="/subscriptions/7251a908-4032-4426-bff1-4201c5a4e690/resourceGroups/BOLDTAZ-PROD-EastUS2-RG-Data-Analytics/providers/Microsoft.Network/virtualNetworks/BOLDTAZ-PROD-EastUS2-RG-Data-Analytics-vnet/subnets/default"
  type    = string
}

variable "networktest" {
  default = "/subscriptions/7251a908-4032-4426-bff1-4201c5a4e690/resourceGroups/BOLDTAZ-PROD-EastUS2-RG-Data-Analytics/providers/Microsoft.Network/networkInterfaces/on-backend-subnet612_z1"
  type    = string
}

