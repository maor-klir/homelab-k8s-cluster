# Reference the shared HCP Terraform application created in the root module
data "azuread_application" "hcpt_application" {
  display_name = "hcpt-application"
}

# Creates a federated identity credential which ensures that the given
# workspace will be able to authenticate to Azure for the "plan" run phase.
#
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential
resource "azuread_application_federated_identity_credential" "hcpt_federated_credential_plan" {
  application_id = data.azuread_application.hcpt_application.id
  display_name   = "hcpt-federated-credential-plan-qa"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://app.terraform.io"
  subject        = "organization:maor:project:Default Project:workspace:pve-k3s-qa:run_phase:plan"
}

# Creates a federated identity credential which ensures that the given
# workspace will be able to authenticate to Azure for the "apply" run phase.
#
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential
resource "azuread_application_federated_identity_credential" "hcpt_federated_credential_apply" {
  application_id = data.azuread_application.hcpt_application.id
  display_name   = "hcpt-federated-credential-apply-qa"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://app.terraform.io"
  subject        = "organization:maor:project:Default Project:workspace:pve-k3s-qa:run_phase:apply"
}
