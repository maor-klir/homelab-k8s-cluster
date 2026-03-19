# HCP Terraform Token Usage

This document provides an overview of all token types used within this project's HCP Terraform setup, their purpose, lifecycle, and usage considerations as of March 2026.

## Token Types

### 1. Agent Tokens

Agent tokens authenticate a self-hosted `tfc-agent` process to an HCP Terraform agent pool.  
They are long-lived credentials that must be treated as secrets and stored securely.

**Characteristics:**

- Created once per agent pool via the HCP Terraform UI or API
- Long-lived — they do not expire automatically but can be revoked manually
- Stored in a local environment file (`/etc/tfc-agent/tfc-agent.env`) on the agent host VM, readable only by the `tfc-agent` system user (`chmod 600`)
- Referenced in the systemd unit via `EnvironmentFile=`; never embedded in the binary or service file directly
- One agent token is sufficient for this homelab since the HCP Terraform Free Edition includes **one self-hosted agent**

**Usage pattern:**

Each time the `tfc-agent` systemd service starts it presents this token to HCP Terraform and registers itself with the configured agent pool.  
The agent then polls HCP Terraform for queued runs assigned to that pool.

**Security considerations:**

- Rotate the token if the host VM is decommissioned, re-imaged, or suspected of compromise
- The host VM running the agent is air-gapped from the internet (Proxmox VE private network); only outbound HTTPS to HCP Terraform is permitted
- Revoke unused tokens through **Settings → Agent pools → Tokens** in the HCP Terraform UI

See [docs/hcp-terraform-agents.md](hcp-terraform-agents.md) for the full setup procedure.

---

### 2. Workload Identity Tokens (Dynamic Provider Credentials)

Workload Identity Tokens are short-lived JWTs that HCP Terraform generates automatically at the start of every plan and apply run.  
They replace long-lived, statically stored cloud credentials and are the mechanism that powers **Dynamic Provider Credentials**.

**How they work:**

1. HCP Terraform acts as an OIDC identity provider (`https://app.terraform.io`)
2. At run start, HCP Terraform mints a signed JWT (Workload Identity Token) containing claims about the run context
3. The Terraform Azure provider exchanges this JWT for a short-lived Azure access token via the [Azure AD federated identity credentials](https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation) trust relationship
4. The Azure access token is used for the duration of the run and is not persisted anywhere

**Token claims (JWT payload):**

| Claim | Description | Example |
|-------|-------------|---------|
| `iss` | Issuer — always HCP Terraform's OIDC endpoint | `https://app.terraform.io` |
| `sub` | Subject — workspace-scoped identifier | `organization:<org>:project:<project>:workspace:<name>:run_phase:<plan\|apply>` |
| `aud` | Audience — must match the federated credential | `api://AzureADTokenExchange` |
| `terraform_organization_id` | Org ID | `org-xxxxxxxxxxxxxxxxx` |
| `terraform_workspace_id` | Workspace ID | `ws-xxxxxxxxxxxxxxxxx` |
| `terraform_workspace_name` | Workspace name | `k3s-prod` |
| `terraform_run_phase` | Run phase | `plan` or `apply` |
| `terraform_run_id` | Unique run ID | `run-xxxxxxxxxxxxxxxxx` |
| `exp` | Expiry timestamp | Unix epoch; tokens are valid for **60 minutes** |
| `iat` | Issued at timestamp | Unix epoch |

**Lifetime:**  
Tokens are valid for **60 minutes**, which is more than sufficient for a typical Terraform plan or apply.  
Because they are generated per run and discarded after expiry, there is no secret rotation burden.

**Azure trust relationship:**  
An Entra ID federated identity credential is configured on the service principal used by Terraform.  
It trusts tokens issued by `https://app.terraform.io` whose `sub` claim matches the workspace-scoped subject pattern.  
This implements [HashiCorp's official Azure Dynamic Credentials example](https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/azure/azure.tf).

**Usage pattern:**

```
HCP Terraform run starts
        │
        ▼
HCP Terraform mints Workload Identity Token (JWT, 60 min TTL)
        │
        ▼
Terraform Azure provider exchanges JWT with Azure AD
        │
        ▼
Azure AD returns short-lived OAuth access token
        │
        ▼
Terraform uses access token for all Azure API calls during the run
        │
        ▼
Run completes — tokens expire and are discarded
```

**No credentials stored in the cluster or repository** — this is the key security advantage over static client secret or certificate-based authentication.

---

### 3. Team and User API Tokens

HCP Terraform also issues personal user tokens and team tokens for humans and CI systems to interact with the HCP Terraform API (e.g., triggering runs, reading state).

These are not part of the automated infrastructure pipeline in this project.  
They are used ad hoc via the HCP Terraform UI or the Terraform CLI for manual operations.

---

## HCP Terraform Free Tier — Usage Summary (March 2026)

| Resource | Free Tier Limit | This Project |
|----------|----------------|--------------|
| Managed resources | 500 | Well within limit |
| Self-hosted agents | 1 | 1 agent (single VM on Proxmox) |
| Concurrent runs | 1 | Adequate for homelab cadence |
| Workspaces | Unlimited | `k3s-qa`, `k3s-prod` (2 workspaces) |
| Users | Unlimited | Single user |
| Workload Identity Token generations | Unlimited | 1 per plan + 1 per apply per run |
| State versions | Unlimited | Persisted per run |
| VCS integrations | Unlimited | GitHub repository connected |

The two active workspaces (`k3s-qa`, `k3s-prod`) each trigger plan + apply operations when infrastructure changes are merged to `main`.  
Typical monthly run cadence for this homelab is low (< 20 runs/month), keeping resource consumption well within Free tier limits.

---

## Token Hygiene Best Practices

1. **Agent tokens** — store only in the environment file, `chmod 600`, never commit to version control
2. **Workload Identity Tokens** — fully automated; no manual handling required
3. **Personal/Team API tokens** — generate with minimal required scope; revoke after use if created for a one-off operation
4. **Audit** — review active agent tokens and team tokens periodically via **Settings → Tokens** in the HCP Terraform UI; revoke any that are no longer needed

---

## References

- [HCP Terraform Dynamic Provider Credentials](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials)
- [Workload Identity Tokens](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/workload-identity-tokens)
- [Azure-specific dynamic credentials setup](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/azure-configuration)
- [HCP Terraform Agents](https://developer.hashicorp.com/terraform/cloud-docs/agents)
- [HCP Terraform Pricing](https://www.hashicorp.com/products/terraform/pricing)
