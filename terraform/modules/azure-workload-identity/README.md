# Azure Workload Identity Federation for Kubernetes

A Terraform module that sets up Azure Workload Identity (AZWI) federation with Kubernetes, enabling secure credential-less authentication between Kubernetes clusters and Azure resources. It provisions an OpenID Connect (OIDC) issuer, Entra ID application, and Azure Key Vault with federated identity credentials for seamless service account integration.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 3.7 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.50 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 3.7.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.57.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.azwi_application](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_federated_identity_credential.azwi_federated_credential](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_service_principal.azwi_service_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_key_vault.akv_azwi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_resource_group.azwi_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group.oidc_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.azwi_kv_secrets_user_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.oidc_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_blob.jwks_document](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.openid_configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_container.oidc_storage_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [external_external.jwks](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_akv_azwi_location"></a> [akv\_azwi\_location](#input\_akv\_azwi\_location) | Azure Key Vault for Azure Workload Identity location | `string` | `"West Europe"` | no |
| <a name="input_akv_azwi_name"></a> [akv\_azwi\_name](#input\_akv\_azwi\_name) | Azure Key Vault for Azure Workload Identity name | `string` | n/a | yes |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | Azure Subscription ID | `string` | n/a | yes |
| <a name="input_azwi_rg"></a> [azwi\_rg](#input\_azwi\_rg) | Azure Workload Identity resource group name | `string` | n/a | yes |
| <a name="input_azwi_rg_location"></a> [azwi\_rg\_location](#input\_azwi\_rg\_location) | Azure Workload Identity resource group location | `string` | `"West Europe"` | no |
| <a name="input_azwi_service_account_name"></a> [azwi\_service\_account\_name](#input\_azwi\_service\_account\_name) | Kubernetes service account name for Azure Workload Identity | `string` | `"workload-identity-sa"` | no |
| <a name="input_azwi_service_account_namespace"></a> [azwi\_service\_account\_namespace](#input\_azwi\_service\_account\_namespace) | Kubernetes namespace for the Azure Workload Identity service account | `string` | `"external-secrets-operator"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (qa, prod) | `string` | n/a | yes |
| <a name="input_oidc_rg"></a> [oidc\_rg](#input\_oidc\_rg) | OIDC issuer resource group name | `string` | n/a | yes |
| <a name="input_oidc_rg_location"></a> [oidc\_rg\_location](#input\_oidc\_rg\_location) | OIDC issuer resource group location | `string` | `"West Europe"` | no |
| <a name="input_oidc_storage_account"></a> [oidc\_storage\_account](#input\_oidc\_storage\_account) | OIDC issuer storage account name | `string` | n/a | yes |
| <a name="input_oidc_storage_container"></a> [oidc\_storage\_container](#input\_oidc\_storage\_container) | OIDC issuer storage container name | `string` | `"$web"` | no |
| <a name="input_workload_identity_public_key_pem"></a> [workload\_identity\_public\_key\_pem](#input\_workload\_identity\_public\_key\_pem) | Workload identity service account public key in PEM format | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | The application ID |
| <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id) | The ID of the Azure Key Vault |
| <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name) | The name of the Azure Key Vault |
| <a name="output_oidc_issuer_uri"></a> [oidc\_issuer\_uri](#output\_oidc\_issuer\_uri) | The OIDC issuer URI |
| <a name="output_service_principal_client_id"></a> [service\_principal\_client\_id](#output\_service\_principal\_client\_id) | The client ID of the Azure AD service principal |
| <a name="output_service_principal_object_id"></a> [service\_principal\_object\_id](#output\_service\_principal\_object\_id) | The object ID of the Azure AD service principal |
<!-- END_TF_DOCS -->
