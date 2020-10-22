# Configure the Azure Provider
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# Configure the local valuess
locals {
  application_name = "Weblate"
  business_unit    = "Marketing"
  environment      = "Prod"
  owner            = "name@example.com"
  requestor        = "name@example.com"
  start_date       = "2020-10-01"
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

# Option 1 (default): Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-weblate-${random_string.random.result}"
  location = "westeurope"
  tags     = local.common_tags
}

# Option 2: Provide an existing resource group
# data  "azurerm_resource_group" "rg" {
#   name     = "rg-weblate-${random_string.random.result}"
# }

# Create Postgres Server
resource "azurerm_postgresql_server" "psql" {
  name                = "psql-weblate-${random_string.random.result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  administrator_login          = var.postgres_user
  administrator_login_password = var.postgres_password

  # sku_name   = "B_Gen5_1" // Minimal Setup
  sku_name   = "GP_Gen5_2"
  version    = "11"
  storage_mb = 10240

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  public_network_access_enabled    = true
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

# Create Postgres Server Firewall Rule
resource "azurerm_postgresql_firewall_rule" "psql_fw" {
  name                = "AllowAccessToAzureServices"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.psql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Create Postgres Database
resource "azurerm_postgresql_database" "db" {
  name                = "weblate"
  resource_group_name = data.azurerm_resource_group.rg.name
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

# NOTE: Redis name needs to be unique globally
resource "azurerm_redis_cache" "redis" {
  name                = "redis-weblate-${random_string.random.result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
}

# Create Cognitive Service
# NOTE: Only one free account is allowed for account type 'TextTranslation'.
resource "azurerm_cognitive_account" "cog" {
  name                = "cog-weblate-${random_string.random.result}"
  location            = "global"
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = "TextTranslation"

  sku_name = "S1"
}

# Create App Service Plan
resource "azurerm_app_service_plan" "plan" {
  name                = "plan-weblate-${random_string.random.result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Create WebApp from Docker Image
resource "azurerm_app_service" "app" {
  name                    = "app-weblate-${random_string.random.result}"
  location                = data.azurerm_resource_group.rg.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  app_service_plan_id     = azurerm_app_service_plan.plan.id
  https_only              = true
  client_affinity_enabled = true
  
  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb = 42
      }
    }
  }
  
  site_config {
    always_on        = true
    http2_enabled    = true
    linux_fx_version = "DOCKER|weblate/weblate:4.2.2-1"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].linux_fx_version
    ]
  }

  app_settings = {
    "DOCKER_ENABLE_CI"                    = "true"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io"
    "MT_MICROSOFT_COGNITIVE_KEY"          = azurerm_cognitive_account.cog.primary_access_key
    "MT_SERVICES"                         = "weblate.machinery.microsoft.MicrosoftCognitiveTranslation"
    "POSTGRES_DATABASE"                   = azurerm_postgresql_database.db.name
    "POSTGRES_HOST"                       = "${azurerm_postgresql_server.psql.name}.postgres.database.azure.com"
    "POSTGRES_PASSWORD"                   = var.postgres_password
    "POSTGRES_PORT"                       = "5432"
    "POSTGRES_SSL_MODE"                   = "require"
    "POSTGRES_USER"                       = "weblate@${azurerm_postgresql_server.psql.name}"
    "POSTGRES_ALTER_ROLE"                 = "weblate"
    "REDIS_HOST"                          = azurerm_redis_cache.redis.hostname
    "REDIS_PASSWORD"                      = azurerm_redis_cache.redis.primary_access_key
    "REDIS_PORT"                          = azurerm_redis_cache.redis.ssl_port
    "REDIS_TLS"                           = "True"
    "WEBLATE_ADMIN_EMAIL"                 = var.admin_email
    "WEBLATE_ADMIN_NAME"                  = var.admin_name
    "WEBLATE_ADMIN_PASSWORD"              = var.admin_password
    "WEBLATE_ALLOWED_HOSTS"               = "app-weblate-${random_string.random.result}.azurewebsites.net,*"
    "WEBLATE_DEBUG"                       = "1"
    "WEBLATE_ENABLE_HTTPS"                = "1"
    "WEBLATE_LOGLEVEL"                    = "INFO"
    "WEBLATE_REGISTRAION_OPEN"            = "1"
    "WEBLATE_SITE_DOMAIN"                 = "app-weblate-${random_string.random.result}.azurewebsites.net"
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS"  = "7"
    "WEBSITES_CONTAINER_START_TIME_LIMIT" = "1800"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "TRUE"
    "WEBSITES_PORT"                       = "8080"
    // Email Server Setup
    "WEBLATE_DEFAULT_FROM_EMAIL"          = var.default_from_email
    "WEBLATE_EMAIL_BACKEND"               = var.email_backend
    "WEBLATE_EMAIL_HOST"                  = var.email_host
    "WEBLATE_EMAIL_PASSWORD"              = var.email_host_password
    "WEBLATE_EMAIL_PORT"                  = var.email_port
    "WEBLATE_EMAIL_USE_SSL"               = var.email_use_ssl
    "WEBLATE_EMAIL_USE_TLS"               = var.email_use_tls
    "WEBLATE_EMAIL_USER"                  = var.email_host_user
    "WEBLATE_SERVER_EMAIL"                = var.server_email
    // Authentication Settings
    "WEBLATE_SOCIAL_AUTH_AZUREAD_OAUTH2_KEY"    = var.social_auth_azure_oauth2_key
    "WEBLATE_SOCIAL_AUTH_AZUREAD_OAUTH2_SECRET" = var.social_auth_azure_oauth2_secret
    "WEBLATE_SOCIAL_AUTH_GITHUB_KEY"            = var.social_auth_github_key
    "WEBLATE_SOCIAL_AUTH_GITHUB_SECRET"         = var.social_auth_github_secret
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
