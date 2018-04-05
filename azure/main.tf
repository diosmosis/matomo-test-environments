variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "app_service_name" {}
variable "location" {
  default = "eastus"
}
variable "mysql_admin_pwd" {}

# TODO: document in readme
# a deployment user must be created manually
# composer extension must be added manually
# enable ssl must be disabled for mysql server before matomo install

provider "azurerm" {
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "matomo_resource_group" {
    name     = "matomo-azure-test"
    location = "${var.location}"
}

// mysql
resource "azurerm_mysql_server" "matomo_mysql_server" {
  name                = "matomo-mysql-server"
  location            = "${azurerm_resource_group.matomo_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.matomo_resource_group.name}"

  sku {
    name = "MYSQLB50"
    capacity = 50
    tier = "Basic"
  }

  administrator_login = "matomoadmin"
  administrator_login_password = "${var.mysql_admin_pwd}"
  version = "5.7"
  storage_mb = "51200"
  ssl_enforcement = "Enabled"
}

resource "azurerm_mysql_firewall_rule" "matomo_mysql_firewall_rule" {
  name                = "office"
  resource_group_name = "${azurerm_resource_group.matomo_resource_group.name}"
  server_name         = "${azurerm_mysql_server.matomo_mysql_server.name}"
  // allowing all IPs, since app service plan IPs are assigned dynamically apparently
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_mysql_database" "matomo_mysql_database" {
  name                = "matomo"
  resource_group_name = "${azurerm_resource_group.matomo_resource_group.name}"
  server_name         = "${azurerm_mysql_server.matomo_mysql_server.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

// app
resource "azurerm_app_service_plan" "matomo_app_service_plan" {
  name                = "matomo-appserviceplan"
  location            = "${azurerm_resource_group.matomo_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.matomo_resource_group.name}"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

resource "azurerm_app_service" "matomo_app_service" {
  name                = "${var.app_service_name}"
  location            = "${azurerm_resource_group.matomo_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.matomo_resource_group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.matomo_app_service_plan.id}"

  site_config {
    php_version = "7.1"
    scm_type = "LocalGit"
  }

  app_settings {
    "SOME_KEY" = "some-value"
  }
}

// outputs
output "mysql_fqdn" {
  value = "${azurerm_mysql_server.matomo_mysql_server.fqdn}"
}

output "appservice_url" {
  value = "${azurerm_app_service.matomo_app_service.default_site_hostname}"
}

output "appservice_git" {
  value = "${azurerm_app_service.matomo_app_service.source_control.0.repo_url}"
}
