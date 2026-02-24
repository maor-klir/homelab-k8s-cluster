# 🏡☸️ homelab-k8s-cluster

This GitHub repository contains all the documentation and configuration of my first self-hosted homelab Kubernetes environment implemented through [GitOps principles](https://opengitops.dev/) and powered by K3s, Flux, and Cilium.  
Infrastructure provisioning and lifecycle management is handled through HCP Terraform and cloud-init.  
Manual steps on bootstrapping the environment are kept to a minimum to assure a declarative, predictable, and consistent deployment.  
The reasoning behind selecting Cilium as a CNI can be found at [docs/cilium.md](docs/cilium.md).

A second self-hosted Kubernetes environment with a slightly different configuration can be found [here](https://github.com/maor-klir/homelab-k8s-cluster-2).

## 📖 Introduction

This Kubernetes environment was first and foremost conceived for learning purposes and improving my proficiency level on all related domains.  
It all boils down to knowing how to handle such an equivalent environment in production, running business-critical workloads.  
With that in mind, I treat this project with great care and attention to details.  
This mindset forces me to take into account security, identity, scalability, and recovery/rollback strategies and adhere to the respected domain industry's best practices when provisioning different environments and maintaining the deployed workloads.  

Secondly, I plan to self-host some applications for personal usage.  
Self-hosting also drives one to be accountable and responsible to take care of the ease of deployment and maintenance operations over time, in other words - settings up proper automation and applying improvements as the environment matures and thickens.  
That is where GitOps methodologies come into play and provide the necessary structure to treat infrastructure definition as the single source of truth, ensuring that every change is versioned, auditable, and automatically reconciled against the actual environment state. More on that can be found at [docs/gitops.md](docs/gitops.md).

## 🏗️ Underlying Infrastructure

I started out my journey hosting Kubernetes nodes on bare metal, where each node was provisioned onto a single HP EliteDesk 800 G2 DM mini PC.  
Later on I have decided to transition to provisioning each node as a separate VM on a Proxmox VE highly available cluster.  
With that shift, I have also upgraded the host machines to a 3-node HP EliteDesk 800 G4 DM 35W mini PCs (Intel Core i5-8500T (6c/6t) / 32GB RAM / 256GB SSD NVMe).  

This VM-based approach embraces Infrastructure as Code best practices through a modular, multi-layered architecture:

- **Terraform Modules**: Reusable `k3s-cluster` and `azure-workload-identity` modules sourced from HCP Terraform private registry provision infrastructure consistently across environments, parameterized by environment-specific variables (node count, IP ranges, VM IDs). Local module definitions are maintained in `/terraform/modules` for reference and showcase implementation details
- **Environment Separation**: Dedicated `/terraform/environments/{qa,prod}` directories instantiate modules with environment-specific configurations while maintaining DRY principles
- **GitOps with Flux**: Kustomize-based overlays (e.g. `/infrastructure/{controllers,configs}/{base,qa,prod}`) enable declarative configuration management where base resources are patched per-environment, eliminating hardcoded values and ensuring environment-specific configurations are isolated
- **Automated Provisioning**: Cloud-init templates combined with shell scripts bootstrap K3s clusters with OIDC configuration, workload identity keys, and Cilium CNI - fully automated from VM creation to cluster readiness

This architecture ensures all infrastructure is version-controlled, auditable, and reproducible.  
Environments can be destroyed and recreated identically, eliminating configuration drift while enabling rapid iteration and testing workflows.

## ⚙️ Core Components and Key Features

- [K3s](https://k3s.io/): a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances
- [Flux](https://fluxcd.io/): a tool that follows [GitOps principles](https://opengitops.dev/#principles) for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories), and automating updates to configuration when there is new code to deploy
- [Cilium](https://cilium.io): an eBPF-based networking, observability, and security solution for Kubernetes. Cilium serves as the cluster's [CNI](https://www.cni.dev) and [Gateway API controller](https://gateway-api.sigs.k8s.io/)
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner): dynamically provision persistent local storage with Kubernetes
- [cert-manager](https://cert-manager.io/): cloud-native certificate management for Kubernetes
- [External Secrets Operator](https://external-secrets.io/latest/): a Kubernetes operator that integrates external secret management systems (in this specific case, Azure Key Vault)
- [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/latest): control DNS records dynamically via Kubernetes resources in a DNS provider-agnostic way (only Cloudflare in my case)
- [Azure Workload Identity Federation with OpenID Connect (OIDC)](https://azure.github.io/azure-workload-identity/docs/introduction.html): enables workloads deployed on the Kubernetes cluster a secure access to Azure resources without the maintenance burden of manually managing credentials. The Kubernetes cluster serves as the OIDC tokens issuer. This modern practice eliminates the risk of leaking long-lived secrets stored within the cluster or having certificates expire
- [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/): a secure way to reach our deployed applications from the internet without compromising security as a lightweight daemon (`cloudflared`) deployed on the cluster creates outbound-only connections to Cloudflare's global network
- [Cluster Load Balancer](https://docs.k3s.io/datastore/cluster-loadbalancer): a three-node HAProxy/Keepalived setup provides HA load balancing for the K3s control planes. The shared VIP serves as an endpoint to access the K3s Prod cluster API server and as a fixed registration address for joining nodes. Priority-based automatic failover ensures continuous availability with redundancy of two levels of failure. More info can be found at [docs/cluster-load-balancer.md](docs/cluster-load-balancer.md).
- [Automated K3s cluster upgrade](https://docs.k3s.io/upgrades/automated): a Kubernetes-native approach to cluster upgrades. Leverages a custom Kubernetes [controller](https://github.com/rancher/system-upgrade-controller) and [Custom Resource](https://docs.k3s.io/upgrades/automated#configuration) to declaratively describe what nodes to upgrade, and to what version
- [Mend Renovate](https://github.com/renovatebot/renovate): Automated dependency updates. Renovate automatically identifies outdated dependencies and creates pull requests to ensure that container images (Helm releases are also supported) are always current

## 🔁 Infrastructure Lifecycle Management

### Build → Deploy → Manage

The K3s environment relies on infrastructure provisioning and management through HCP Terraform, cloud-init, and shell scripts.  
Since all infrastructure is being provisioned on a Proxmox VE cluster that has no publicly accessible endpoint, i.e., an isolated private environment, an HCP Terraform agent must be present and running on the private network (I opted for a binary running on a small-sized VM).  
General considerations and implementation specifics can be found at [docs/hcp-terraform-agents.md](docs/hcp-terraform-agents.md).

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
  My implementation follows [HashiCorp's official Azure setup example](https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/azure/azure.tf), extended with additional Azure and Entra ID role assignments.  
  These assignments enable Terraform to assign roles to provisioned resources and manage Entra ID applications and service principals.

- [**Terraform Workload Identity**](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/workload-identity-tokens) is the mechanism that powers _dynamic provider credentials_.  
  It allows HCP Terraform to present information about a Terraform workload to an external system – like its workspace, organization, or whether it’s a plan or apply – and allows other external systems to verify that the information is accurate.  
  This workflow is built on the [OpenID Connect protocol](https://openid.net/connect/), a trusted standard for verifying identity across different systems.

## 📊 Observability

A federated observability stack combining metrics (Prometheus + Thanos) and logs (Loki + Grafana Alloy), both using Azure Blob Storage for long-term persistence.  
Both the Prod and the QA clusters remote-write metrics to a centralized Thanos instance and push logs to Loki running in Prod, providing unified observability across all environments via a single Grafana dashboard.

### Key components

**Metrics:**
- [Prometheus](https://prometheus.io/) - deployed through the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack). Scrapes cluster metrics with 6h local retention, remote-writes everything to Thanos Receive
- [Thanos](https://thanos.io/) - horizontally scalable, highly available query and storage layer providing unlimited retention via object storage. Deployed as native Kubernetes manifests for full configuration control
- [Kube-State-Metrics](https://github.com/kubernetes/kube-state-metrics) - generates metrics about Kubernetes object states
- [Node Exporter](https://github.com/prometheus/node_exporter) - exposes hardware and OS-level metrics from cluster nodes

**Logs:**
- [Loki](https://grafana.com/oss/loki/) - horizontally scalable log aggregation system deployed in distributed mode (microservices architecture), the most production-grade of all three deployment modes. Indexes only metadata (not full-text), dramatically reducing storage costs. Stores compressed log chunks in Azure Blob Storage with 90-day retention
- [Grafana Alloy](https://grafana.com/docs/alloy/latest/) - log collection agent deployed as a DaemonSet (running on every node of the cluster). Autodiscovers pods via the Kubernetes API, extracts Kubernetes metadata, and ships logs to Loki via HTTPS with basic authentication, configured using Alloy's River language

**Visualization & Storage:**
- [Grafana](https://grafana.com/) - visualization dashboards with unified alerting for alert management and notifications. A single centralized instance is deployed. Provides a unified dashboard view across all clusters for both metrics and logs
- [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs) - long-term persistence for both metrics (Thanos) and logs (Loki). Set up with ZRS replication for durability. Metrics stored with automatic downsampling (90d raw, 180d 5m, 365d 1h resolution), logs stored as Snappy-compressed chunks with 90d retention
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/) - unified alerting system for alert management and delivery, replacing the traditional Prometheus Alertmanager

All Thanos and Loki components authenticate to Azure via Workload Identity Federation (no stored credentials).  
External access to Loki is secured via Cilium Ingress with Let's Encrypt TLS and basic authentication.  
Architecture details, data flow, and design rationale specifics are available at [docs/observability.md](docs/observability.md).  

## 📦 Deployed Applications

- [linkding](https://github.com/sissbruecker/linkding) - a self-hosted bookmark manager that is designed to be minimal, fast, and easy to set up
- [Audiobookshelf](https://github.com/advplyr/audiobookshelf) - a self-hosted audiobook and podcast server

## 🗺️ Current Environments

- `k3s-qa` - a 3-node cluster (1 control plane, 2 worker nodes), where all testing and exploration is being made.
- `k3s-prod` - a 6-node HA cluster with embedded etcd (3 control plane nodes, 3 worker nodes), a production environment for running stable and reliable workloads, only promoted after proper testing.  

---

**Note**: This documentation is a working document and will be updated to reflect the ongoing development of the cluster.
