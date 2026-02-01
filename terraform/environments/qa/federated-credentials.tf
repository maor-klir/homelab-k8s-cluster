# Additional federated identity credentials for workload-identity-sa in different namespaces
#
# The azure_workload_identity module creates the base credential for external-secrets-operator.
# This file defines additional namespaces that need to use the same Azure identity.

locals {
  # Map of additional service accounts that need federated credentials
  # Key: unique identifier (used for resource names)
  # Value: object with namespace and service account name
  additional_federated_credentials = {
    # Add namespaces here as needed for QA environment
    # example:
    # thanos = {
    #   namespace           = "thanos"
    #   service_account     = "workload-identity-sa"
    #   description         = "Kubernetes service account federated credential for Thanos"
    # }
  }
}

# Create federated identity credentials for each namespace
resource "azuread_application_federated_identity_credential" "additional_credentials" {
  for_each = local.additional_federated_credentials

  application_id = module.azure_workload_identity.application_id
  display_name   = "kubernetes-federated-credential-qa-${each.key}"
  description    = each.value.description
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = module.azure_workload_identity.oidc_issuer_uri
  subject        = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}
