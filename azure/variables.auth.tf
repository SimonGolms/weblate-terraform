// AUTHENTICATION SETTINGS

// (Optional): Enables Azure AD 
variable "social_auth_azure_oauth2_key" {
  type = string
  default = null
  description = "Enables Azure Active Directory authentication."
}

variable "social_auth_azure_oauth2_secret"   {
  type = string
    default = null
  description = "Enables Azure Active Directory authentication."
}

// (Optional): Enables GitHub Authentication
variable "social_auth_github_key" {
  type = string
  default = null
  description = "Enables GitHub Authentication."
}

variable "social_auth_github_secret" {
  type = string
  default = null
  description = "Enables GitHub Authentication"
}
