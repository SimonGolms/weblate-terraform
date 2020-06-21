terraform {
  required_version = ">= 0.12"
}

# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.15.0"
  features {}
}

# Configure the local values
locals {
  application_name = "Weblate"
  business_unit    = "Marketing"
  environment      = "Prod"
  owner            = "name@example.com"
  requestor        = "name@example.com"
  start_date       = "2020-06-01"
  end_date         = "2021-01-01"

  common_tags = {
    ApplicationName = local.application_name
    BusinessUnit    = local.business_unit
    Environment     = local.environment
    Owner           = local.owner
    Requestor       = local.requestor
    StartDate       = local.start_date
    EndDate         = local.end_date
  }
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-weblate"
  location = "westeurope"
  tags     = local.common_tags
}

# Create Postgres Server
resource "azurerm_postgresql_server" "psql" {
  name                = "psql-weblate"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login          = var.postgres_user
  administrator_login_password = var.postgres_password

  # sku_name   = "B_Gen5_1"
  sku_name   = "GP_Gen5_2"
  version    = "11"
  storage_mb = 10240

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

# Create Postgres Server Firewall Rule
resource "azurerm_postgresql_firewall_rule" "psql_fw" {
  name                = "AllowAllWindowsAzureIps"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.psql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Create Postgres Database
resource "azurerm_postgresql_database" "db" {
  name                = "weblate"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.psql.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# Create Redis Cache
resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "redis" {
  name                = "redis-weblate-${random_string.random.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
}

# Create Cognitive Service
# NOTE: Only one free account is allowed for account type 'TextTranslation'.
resource "azurerm_cognitive_account" "cog" {
  name                = "cog-weblate"
  location            = "global"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "TextTranslation"

  sku_name = "F0"
}

# Create App Service Plan
resource "azurerm_app_service_plan" "plan" {
  name                = "plan-weblate"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Create WebApp from Docker Image
resource "azurerm_app_service" "app" {
  name                = "app-weblate"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|weblate/weblate:4.1.1-1"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].linux_fx_version
    ]
  }

  app_settings = {
    "MT_SERVICES"                         = "weblate.machinery.microsoft.MicrosoftCognitiveTranslation"
    "MT_MICROSOFT_COGNITIVE_KEY"          = azurerm_cognitive_account.cog.primary_access_key
    "POSTGRES_DATABASE"                   = azurerm_postgresql_database.db.name
    "POSTGRES_HOST"                       = "psql-weblate-prod.postgres.database.azure.com"
    "POSTGRES_PASSWORD"                   = var.postgres_password
    "POSTGRES_PORT"                       = "5432"
    "POSTGRES_USER"                       = "weblate@psql-weblate-prod"
    "POSTGRES_SSL_MODE"                   = "prefer"
    "REDIS_HOST"                          = azurerm_redis_cache.redis.primary_connection_string
    "REDIS_PASSWORD"                      = azurerm_redis_cache.redis.primary_access_key
    "REDIS_PORT"                          = azurerm_redis_cache.redis.port
    "REDIS_TLS"                           = "True"
    "WEBLATE_ADMIN_EMAIL"                 = var.admin_email
    "WEBLATE_ADMIN_NAME"                  = var.admin_name
    "WEBLATE_ADMIN_PASSWORD"              = var.admin_password
    "WEBLATE_ALLOWED_HOSTS"               = "*"
    "WEBLATE_DEBUG"                       = "1"
    "WEBLATE_DEFAULT_FROM_EMAIL"          = "no-reply@weblate.com"
    "WEBLATE_EMAIL_HOST"                  = "127.0.0.1"
    "WEBLATE_LOGLEVEL"                    = "DEBUG"
    "WEBLATE_REGISTRAION_OPEN"            = "1"
    "WEBLATE_SERVER_EMAIL"                = "no-reply@weblate.com"
    "WEBSITES_CONTAINER_START_TIME_LIMIT" = "1800"
    "WEBSITES_PORT"                       = "8080"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "TRUE"
  }

}

output "instance_site" {
  value       = azurerm_app_service.app.default_site_hostname
  description = "The address of your Weblate instance."
}

output "instance_admin_email" {
  value       = var.admin_email
  description = "The email address for logging in to the instance."
}

output "instance_admin_password" {
  value       = var.admin_password
  description = "The password for logging in to the instance."
  sensitive   = true
}
