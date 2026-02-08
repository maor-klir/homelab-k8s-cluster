# Observability Stack

## Overview

A federated observability stack combining metrics (Prometheus + Thanos) and logs (Loki + Promtail), both using Azure Blob Storage for long-term persistence.
Both Prod and the QA clusters remote-write metrics to a centralized Thanos instance and push logs to Loki running in Prod, providing unified observability across all environments via a single Grafana dashboard.

### Metrics Data Flow

1. Prometheus scrapes metrics from cluster targets (nodes, pods, services)
2. Prometheus remote-writes all metrics to Thanos Receive Router
3. Thanos Receive Router distributes metrics to Thanos Receive Ingestor replicas (hashring-based)
4. Thanos Receive Ingestor persists metrics to Azure Blob Storage
5. Thanos Store Gateway serves historical metrics from Azure Blob Storage
6. Thanos Query aggregates data from Thanos Receive Ingestor (recent) and Thanos Store Gateway (historical)
7. Thanos Query Frontend caches queries and splits large time ranges
8. Grafana queries Thanos Query Frontend for visualization and alerting

### Logs Data Flow

1. Promtail DaemonSet tails log files from `/var/log/pods/*` on every node
2. Promtail extracts Kubernetes metadata (namespace, pod, container, labels) and parses CRI format logs
3. Promtail ships logs to Loki Gateway via HTTPS with basic authentication
4. Loki Gateway authenticates requests and forwards to Loki Distributor
5. Loki Distributor validates log entries and forwards to Loki Ingester replicas (consistent hashing)
6. Loki Ingester builds compressed chunks in memory and periodically flushes to Azure Blob Storage
7. Loki Querier serves recent logs from Ingesters (in-memory) and historical logs from Azure Blob Storage via Index Gateway
8. Loki Query Frontend splits large queries and caches results
9. Grafana queries Loki Query Frontend for log visualization and exploration

## Components

### Prometheus

The metrics collection engine. Scrapes targets across the cluster and forwards all data to Thanos for long-term storage.

- Short retention (6h) - acts as metrics buffer, not long-term storage
- Remote-writes all metrics to Thanos Receive
- Includes kube-state-metrics and node-exporter
- Adds cluster/environment labels for multi-cluster identification

### Thanos

Horizontally scalable metrics storage and query layer built on top of Prometheus. Thanos adds long-term retention, multi-cluster aggregation, and deduplication capabilities that Prometheus alone cannot provide. Deployed as native Kubernetes manifests (not Helm) for full control over configuration and component independence.

- Deduplicates metrics from replicated Prometheus instances via content-based addressing
- Stores block-based data in Azure Blob Storage with automatic tiered downsampling
- Caches query results and query planning to reduce redundant and overlapping requests
- Single instance Compact component downsamples data to configured retention tiers (90/180/365 days)
- No stored credentials — authenticates to Azure via Workload Identity Federation

| Component | Replicas | Purpose | Replicas Count Reasoning |
|-----------|----------|---------|----------------|
| Receive Router | 2 | Load balances incoming remote-writes | HA for write path; survives single pod failure without write interruption |
| Receive Ingestor | 2 | Writes metrics to Azure Blob Storage | Matches hashring configuration; each ingestor handles different metric series via consistent hashing |
| Store Gateway | 2 | Serves historical data from object storage | HA for historical queries; both instances cache different block metadata |
| Query | 2 | Aggregates data from all stores | HA for query path; distributes query load across instances |
| Query Frontend | 2 | Caches queries, splits large requests | HA for Grafana access; shares query cache for efficiency |
| Compact | 1 | Downsamples and deduplicates blocks | Single instance prevents coordination conflicts; multiple instances would conflict over which blocks to compact |

### Azure Blob Storage

Long-term persistence layer for both metrics and logs. Provides unlimited retention at low cost with ZRS replication for durability.  
Both Thanos and Loki authenticate via Azure Workload Identity (no stored credentials).

**Metrics (Thanos):**
- Tiered retention: 90d raw, 180d 5m, 365d 1h resolution
- Automatic downsampling via Thanos Compact

**Logs (Loki):**
- Snappy-compressed chunks stored in Azure containers
- 90-day retention with automatic deletion via Loki Compactor

### Grafana

Centralized visualization and alerting interface. Single instance in prod cluster provides a unified view of metrics and logs across all environments.

- Queries Thanos Query Frontend (federated metrics view)
- Queries Loki Query Frontend (federated logs view)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/) for unified alert management and notifications (the traditional Prometheus Alertmanager is disabled)

### Loki

Horizontally scalable log aggregation and query system inspired by Prometheus. Deployed in distributed mode (microservices architecture) via Helm, the most production-grade of all three deployment modes (monolithic, simple scalable, distributed).

- Indexes metadata only (namespace, pod, container, labels), not log content — dramatically reduces storage costs
- Compresses log chunks with Snappy before writing to Azure Blob Storage
- 90-day retention with automatic deletion via Compactor
- Authentication via Azure Workload Identity (no stored credentials)

| Component | Replicas | Purpose | Replicas Count Reasoning |
|-----------|----------|---------|----------------|
| Gateway | 1 | Handles external access with basic auth and TLS | Single entry point for all read/write traffic; Helm chart default |
| Distributor | 3 | Validates logs and routes to Ingesters | HA for write path; distributes load across instances |
| Ingester | 3 | Writes log chunks to Azure Blob Storage | Matches replication factor (RF=3); each log stream replicated across 3 ingesters |
| Querier | 3 | Executes LogQL queries against Ingesters and storage | HA for query path; distributes query load |
| Query Frontend | 2 | Splits queries, caches results | HA for Grafana access; shared query cache |
| Query Scheduler | 2 | Schedules and distributes queries to Queriers | HA for query scheduling; decouples frontend from queriers |
| Index Gateway | 2 | Serves TSDB index for queries | HA for index lookups; both instances cache index data |
| Compactor | 1 | Retention enforcement, compaction | Single instance prevents conflicts over which chunks to compact |
| Ruler | 1 | Evaluates recording/alerting rules | Single instance to avoid duplicate alert firing |
| Chunks Cache | 1 | Caches frequently accessed log chunks in memory (512MB) | Reduces object storage reads; single instance sufficient for current load |
| Canary | DaemonSet | Pushes synthetic logs and queries them back to verify end-to-end pipeline health | One pod per node; exposes Prometheus metrics on push latency, query success, and missing entries |

### Promtail

Lightweight log collection agent deployed as a DaemonSet. One pod runs on every node (including control plane).

- Tails container logs from `/var/log/pods/*`
- Autodiscovers all pods via Kubernetes API
- Extracts metadata (namespace, pod, container, app labels)
- Parses CRI format logs (containerd/cri-o)
- Filters out low-value namespaces (kube-public, kube-node-lease)
- Ships logs to Loki Gateway via HTTPS with basic authentication
- Tracks processed log positions to prevent duplication after restarts
- Runs as root (UID 0) to read log files but without privileged mode
- Resource requests: 100m CPU, 64Mi memory; limits: 200m CPU, 128Mi memory

## Why This Architecture?

#### Multi-cluster federation:

Both Prod and QA clusters remote-write metrics to the same Thanos instance and push logs to the same Loki instance running in prod.  
Each cluster's Prometheus adds unique labels (cluster=prod/qa, environment=prod/qa) and Promtail adds cluster labels to enable filtering and aggregation across environments.  
QA writes metrics to `https://thanos-receive.cloudandklir.com` and logs to `https://loki-gateway.cloudandklir.com` (both exposed via Cilium Ingress), while Prod writes metrics directly to in-cluster Thanos services and logs to the same Loki Gateway Ingress endpoint.  
Adding additional clusters requires only configuring their Prometheus remote-write endpoint and Promtail client URL—no changes to storage or query layers.  
The single Grafana instance in Prod provides a unified view of metrics and logs across all environments.

#### Scalability:

Prometheus alone doesn't scale for multi-cluster or long retention. Loki alone doesn't handle massive log volumes without horizontal scaling.
Thanos adds horizontal scalability for metrics and unlimited retention via object storage. Loki's distributed mode allows scaling write and query paths independently.

#### Cost efficiency:

Azure Blob Storage is significantly cheaper than block storage for metrics and logs.
Loki indexes only metadata (not full-text), dramatically reducing storage costs.
Thanos downsampling reduces metrics storage costs over time.

#### No credential management:

Azure Workload Identity eliminates secret rotation burden for both Thanos and Loki. The cluster's OIDC issuer authenticates directly with Entra ID.

#### Separation of concerns:

Each Thanos and Loki component has a single responsibility, making troubleshooting and scaling straightforward.

#### Unified observability:

Metrics and logs in a single Grafana instance enable correlation (e.g., metrics spike → query logs from same timeframe).
LogQL (Loki Query Language) is similar to PromQL, reducing learning curve.

#### GitOps native:

Both deployments integrate cleanly with Flux and Kustomize overlays. Loki uses Helm but with explicit configuration rather than relying on chart defaults.

## Security Considerations

**Metrics (Thanos):**
- All Thanos components run as non-root (UID 65534)
- Read-only root filesystems
- Dropped capabilities
- Azure authentication via federated identity tokens (no long-lived secrets)

**Logs (Loki):**
- Loki components run as non-root with dropped capabilities
- Promtail runs as root (UID 0) to read log files but without privileged mode
- Read-only root filesystems
- External access via Cilium Ingress with Let's Encrypt TLS
- Gateway protected by basic authentication (htpasswd format)
- Azure authentication via federated identity tokens (no long-lived secrets)

**Secrets Management:**
- All secrets pulled from Azure Key Vault via External Secrets Operator
- Basic auth credentials for Loki stored as htpasswd hash (not plaintext)
- Promtail credentials injected via Helm valuesFrom (Secret references)
