# 🏡☸️ homelab-k8s-cluster

This GitHub repository contains all the documentation and configuration of my first self-hosted homelab Kubernetes environment implemented through [GitOps principles](https://opengitops.dev/) and powered by K3s, Flux, and Cilium.
Infrastructure provisioning and lifecycle management is handled through HCP Terraform and cloud-init.
Manual steps on bootstrapping the environment are kept to a minimum to assure a declarative, predictable, and consistent deployment.

A second self-hosted Kubernetes environment with a slightly different configuration can be seen [here](https://github.com/maor-klir/homelab-k8s-cluster-2).

## 📖 Introduction

This Kubernetes environment was first and foremost conceived for learning purposes and improving my proficiency level on all related domains.
It all boils down to knowing how to handle such an equivalent environment in production, running business-critical workloads.
With that in mind, I treat this project with great care and attention to details.
This mindset forces me to take into account security, identity, scalability, and recovery/rollback strategies and adhere to the respected domain industry's best practices when provisioning different environments and maintaining the deployed workloads.

Secondly, I plan to self-host some applications for personal usage.
Self-hosting also drives one to be accountable and responsible to take care of the ease of deployment and maintenance operations over time, in other words - settings up proper automation and applying improvements as the environment matures and thickens.
That is where GitOps methodologies come into play and provide the necessary structure to treat infrastructure definition as the single source of truth, ensuring that every change is versioned, auditable, and automatically reconciled against the actual environment state. More on that can be viewed [here](docs/gitops.md).

## 🏗️ Underlying Infrastructure

I started out my journey hosting Kubernetes nodes on bare metal, where each node was provisioned onto a single HP EliteDesk 800 G2 DM mini PC.
Later on I have decided to transition to provisioning each node as a separate VM on a Proxmox VE highly available cluster.
With that shift, I have also upgraded the host machines to a 3-node HP EliteDesk 800 G4 DM 35W mini PCs (Intel Core i5-8500T (6c/6t) / 32GB RAM / 256GB SSD NVMe).

This approach enables me to provision and bootstrap clusters more quickly, easily, and with less overhead through HCP Terraform and cloud-init, eliminating manual configuration steps and ensuring consistent, reproducible deployments across environments.

## ⚙️ Core Components and Key Features

- [K3s](https://k3s.io/): a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.
  K3s is packaged as a single binary that reduces the dependencies and steps needed to install, run, and auto-update a production Kubernetes cluster.
- [Flux](https://fluxcd.io/): a tool that follows [GitOps principles](https://opengitops.dev/#principles) for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories), and automating updates to configuration when there is new code to deploy
- [Cilium](https://cilium.io): an eBPF-based networking, observability, and security solution for Kubernetes. Cilium serves as the cluster's [CNI](https://www.cni.dev) and [Gateway API controller](https://gateway-api.sigs.k8s.io/)
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner): dynamically provision persistent local storage with Kubernetes
- [cert-manager](https://cert-manager.io/): cloud-native certificate management for Kubernetes
- [External Secrets Operator](https://external-secrets.io/latest/): a Kubernetes operator that integrates external secret management systems (in this specific case, Azure Key Vault)
- [Azure Workload Identity Federation with OpenID Connect (OIDC)](https://azure.github.io/azure-workload-identity/docs/introduction.html) - enables workloads deployed on the Kubernetes cluster a secure access to Azure resources without the maintenance burden of manually managing credentials. The Kubernetes cluster serves as the OIDC tokens issuer. This modern practice eliminates the risk of leaking long-lived secrets stored within the cluster or having certificates expire
- [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/) - a secure way to reach our deployed applications from the internet without compromising security as a lightweight daemon (`cloudflared`) deployed on the cluster creates outbound-only connections to Cloudflare's global network
- [Automated K3s cluster upgrade](https://docs.k3s.io/upgrades/automated): a Kubernetes-native approach to cluster upgrades. Leverages a custom Kubernetes [controller](https://github.com/rancher/system-upgrade-controller) and [Custom Resource](https://docs.k3s.io/upgrades/automated#configuration) to declaratively describe what nodes to upgrade, and to what version
- [Mend Renovate](https://github.com/renovatebot/renovate): Automated dependency updates. Renovate automatically identifies outdated dependencies and creates pull requests to ensure that container images (Helm releases are also supported) are always current

## 🔁 Infrastructure Lifecycle Management

### Build `-->` Deploy `-->` Manage

The K3s environment relies on infrastructure provisioning and management through HCP Terraform and cloud-init.
Since all infrastructure is being provisioned on a Proxmox VE cluster that has no publicly accessible endpoint, i.e., an isolated private environment, an HCP Terraform agent must be present and running on the private network (I opted for a binary running on a small-sized VM).
General considerations and implementation specifics can be seen [here](docs/hcp-terraform-agents.md).

An overview of all the features I am utilizing:

- [**HCP Terraform**](https://developer.hashicorp.com/terraform/cloud-docs) is a hosted service that helps to manage Terraform runs in a consistent and reliable environment.
  It is a modern way that facilitates the management of shared Terraform state and secret data.
  Terraform runs managed by HCP Terraform are called _remote operations._ Remote runs can be initiated by webhooks from a VCS provider, by UI controls within HCP Terraform, by API calls, or by Terraform CLI.
  When using Terraform CLI to perform remote operations, the progress of the run is streamed to the user's terminal, to provide an experience equivalent to local operations.

- [**HCP Terraform Agents**](https://developer.hashicorp.com/terraform/cloud-docs/agents) let us manage isolated, private, or on-premises infrastructure while keeping our network secure.
  By deploying lightweight self-hosted agents within a specific network segment, we can establish a simple connection between our environment and HCP Terraform, facilitating provisioning and management operations.
  The agent requires only outbound connectivity to HCP Terraform, enabling private networks to remain secure. No special networking configuration or exceptions are typically needed.

- [**Dynamic provider credentials**](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials) improve our security posture by letting us provision new, temporary credentials for every Terraform run.
  A trust relationship between our cloud platform(s) and HCP Terraform is configured.
  As part of that process, we can define rules that let HCP Terraform workspaces and runs access specific resources on the specific cloud platform.

- [**Terraform Workload Identity**](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/workload-identity-tokens) is the mechanism that powers _dynamic provider credentials_.
  It allows HCP Terraform to present information about a Terraform workload to an external system – like its workspace, organization, or whether it’s a plan or apply – and allows other external systems to verify that the information is accurate.
  This workflow is built on the [OpenID Connect protocol](https://openid.net/connect/), a trusted standard for verifying identity across different systems.

## 📊 Monitoring

Observability tools are essential and highly important when provisioning and maintaining any modern environment.
The [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) is deployed as the cluster's monitoring solution, providing comprehensive metrics collection, visualization, and alerting capabilities.

The stack includes:
- [Prometheus](https://prometheus.io/) - metrics collection and storage with 30-day retention and 50Gi persistent storage
- [Grafana](https://grafana.com/) - visualization dashboards with unified alerting for alert management and notifications
- [Kube-State-Metrics](https://github.com/kubernetes/kube-state-metrics) - generates metrics about Kubernetes object states
- [Node Exporter](https://github.com/prometheus/node_exporter) - exposes hardware and OS-level metrics from cluster nodes
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/) - unified alerting system for alert management and delivery, replacing the traditional Prometheus Alertmanager

Both Prometheus and Grafana are configured with persistent storage and resource constraints to ensure reliable long-term operation.

## 📦 Deployed Applications

- [linkding](https://github.com/sissbruecker/linkding) - a self-hosted bookmark manager that is designed to be minimal, fast, and easy to set up
- [Audiobookshelf](https://github.com/advplyr/audiobookshelf) - a self-hosted audiobook and podcast server

## 🗺️ Current Environments

- `k3s-staging` - a 3-node cluster, where all testing and exploration is being made

Currently there is only one sole Kubernetes cluster provisioned where all testing and exploration is being made.
(a change to two separate environments is planned and pending - `staging` and `prod`)

This change will represent a real life scenario where (at least) two separate clusters (environments) are present, allowing for testing and exploration on one, while the other environment will host a production environment for running stable and reliable workloads, only promoted after proper testing.

---

**Note**: This documentation is a working document and will be updated to reflect the ongoing development of the cluster.
