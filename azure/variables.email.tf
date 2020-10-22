// EMAIL SERVER SETUP

variable "email_host" {
  type = string
  default = null
  description = "Mail server hostname or IP address."
}

variable "email_port"   {
  type = number
  default = 25
  description = "Mail server port, defaults to 25."
}

variable "email_host_user" {
  type = string
  default = null
  description = "E-mail authentication user."
}

variable "email_host_password" {
  type = string
  default = null
  description = "E-mail authentication password."
}

variable "email_use_ssl" {
  type = number
  default = 0
  description = "Whether to use an implicit TLS (secure) connection when talking to the SMTP server. It is generally used on port 465."
}

variable "email_use_tls" {
  type = number
  default = 1
  description = "Whether to use a TLS (secure) connection when talking to the SMTP server. This is used for explicit TLS connections, generally on port 587 or 25."
}

variable "email_backend" {
  type = string
  default = "django.core.mail.backends.smtp.EmailBackend"
  description = "To disable sending e-mails by Weblate set to 'django.core.mail.backends.dummy.EmailBackend'"
}

variable "server_email" {
  type = string
  default = "root@localhost"
  description = "The e-mail address that error messages come from."
}

variable "default_from_email" {
  type = string
  default = "webmaster@localhost"
  description = "Default e-mail address to use for various automated correspondence."
}
