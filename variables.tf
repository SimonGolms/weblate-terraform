variable "postgres_user" {
  type        = string
  default     = "weblate"
  description = "PostgreSQL username"
}

variable "postgres_password" {
  type        = string
  default     = "weblate"
  description = "PostgreSQL password"
}

variable "admin_name" {
  type        = string
  default     = "Admin"
  description = "Sets the name for the admin user."
}

variable "admin_email" {
  type        = string
  default     = "name@example.com"
  description = "Sets the email adress for the admin user."
}

variable "admin_password" {
  type        = string
  default     = "admin"
  description = "Sets the password for the admin user."
}
