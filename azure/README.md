# Weblate-Terraform <!-- omit in toc -->

<p>
  <a href="#" target="_blank">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg" />
  </a>
</p>

> Build and manage your personal Weblate instance with Terraform under Azure

## Overview

- Azure App
- Azure Cognitive Service (TextTranslation)
- Postgres Server / Database
- Redis

### Estimated Costs

- This setup can be operated under minimal conditions at about 50\$ per month
- With better conditions you will need about 480-500\$ per month

## Prerequisite

- [Installed Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Signed in with the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)

```sh
az login
```

## Install

```sh
terraform init
```

## Usage

```sh
terraform apply
```

## Further Configuration

### Email Server Setup (SendGrid)

1. Create a SendGrid App on Azure: https://blog.mailtrap.io/azure-send-email/
1. Create a SendGrid Instance on Azure https://portal.azure.com/#create/Sendgrid.sendgrid_azure

   - Subscription: `<YOUR_SUBSCRIPTION>`
     - Resource Group: `weblate-rg`
   - Location: `(Europe) West Europe`
   - Name: `weblate`
   - Password: `<PASSWORD>`
   - First Name: `<FIRST_NAME>`
   - Last Name: `<LAST_NAME>`
   - Email: `<EMAIL_ADDRESS>`
   - Company: `<COMPANY>`
   - Website: `example.com`

1. Click on `Manage` and confirm your email adress
1. Create new Sender Identity
1. Create new API Key (SMTP Relay): https://app.sendgrid.com/guide/integrate/langs/smtp


    - API Key Name: `weblate`

2. Update variable value of `email_host`, `email_port`, `email_host_user` and `email_host_password` in `variables.email.tf` or run

```sh
terraform apply -var="email_host=smtp.sendgrid.net" -var"email_port=587" -var="email_host_user=apiKey" -var="email_host_password=<PASSWORD>" -var=""
```

### Social Authentication

#### Azure AD

Update variable value of `social_auth_azure_oauth2_key` and `social_auth_azure_oauth2_secret` in `variables.auth.tf` or run

```sh
terraform apply -var="social_auth_azure_oauth2_key=<KEY>" -var="social_auth_azure_oauth2_secret=<SECRET>"
```

#### GitHub AD

Update variable value of `social_auth_github_key` and `social_auth_github_secret` in `variables.auth.tf` or run

```sh
terraform apply -var="social_auth_github_key=<KEY>" -var="social_auth_github_secret=<SECRET>"
```

---

## Author

**Simon Golms**

- Github: [@SimonGolms](https://github.com/SimonGolms)
- Website: [gol.ms](https://gol.ms)

## Contributing

Contributions, issues and feature requests are welcome!<br />Feel free to check [issues page](https://github.com/simongolms/weblate-terraform/issues).

## Show Your Support

Give a ⭐️ if this project helped you!

## License

Copyright © 2020 [Simon Golms](https://github.com/SimonGolms).<br />
This project is [MIT](https://github.com/simongolms/weblate-terraform/blob/master/LICENSE) licensed.

## Resources

- Terraform
  - Documentation: https://www.terraform.io/docs/index.html
  - Documentation - Azure Provider: https://www.terraform.io/docs/providers/azurerm/index.html
- Weblate
  - Docker: https://hub.docker.com/r/weblate/weblate
  - Documentation: https://docs.weblate.org/en/latest/index.html
