# Observability Stack

## Overview

The observability stack follows a federated metrics architecture using Prometheus for collection and Thanos for long-term storage and multi-cluster querying.

### Data Flow

1. Prometheus scrapes metrics from cluster targets (nodes, pods, services)
2. Prometheus remote-writes all metrics to Thanos Receive Router
3. Thanos Receive Router distributes metrics to Thanos Receive Ingestor replicas (hashring-based)
4. Thanos Receive Ingestor persists metrics to Azure Blob Storage
5. Thanos Store Gateway serves historical metrics from Azure Blob Storage
6. Thanos Query aggregates data from Thanos Receive Ingestor (recent) and Thanos Store Gateway (historical)
7. Thanos Query Frontend caches queries and splits large time ranges
8. Grafana queries Thanos Query Frontend for visualization and alerting

## Components

### Prometheus

The metrics collection engine. Scrapes targets across the cluster and forwards all data to Thanos for long-term storage.

- Short retention (6h) - acts as metrics buffer, not long-term storage
- Remote-writes all metrics to Thanos Receive
- Includes kube-state-metrics and node-exporter
- Adds cluster/environment labels for multi-cluster identification

### Thanos

Horizontally scalable metrics storage and query layer. Deployed as native Kubernetes manifests (not Helm) for full control over configuration.

| Component | Replicas | Purpose | Replicas Count Reasoning |
|-----------|----------|---------|----------------|
| Receive Router | 2 | Load balances incoming remote-writes | HA for write path; survives single pod failure without write interruption |
| Receive Ingestor | 2 | Writes metrics to Azure Blob Storage | Matches hashring configuration; each ingestor handles different metric series via consistent hashing |
| Store Gateway | 2 | Serves historical data from object storage | HA for historical queries; both instances cache different block metadata |
| Query | 2 | Aggregates data from all stores | HA for query path; distributes query load across instances |
| Query Frontend | 2 | Caches queries, splits large requests | HA for Grafana access; shares query cache for efficiency |
| Compact | 1 | Downsamples and deduplicates blocks | Single instance prevents coordination conflicts; multiple instances would conflict over which blocks to compact |

### Azure Blob Storage

Long-term metrics persistence layer. Provides unlimited retention at low cost with automatic tiered downsampling.

- ZRS replication for durability
- Tiered retention: 90d raw, 180d 5m, 365d 1h resolution
- Authentication via Azure Workload Identity (no stored credentials)

### Grafana

Centralized visualization and alerting interface. Single instance in prod cluster provides a unified view across all environments.

- Queries Thanos Query Frontend (federated view of all clusters)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/) for unified alert management and notifications (the traditional Prometheus Alertmanager is disabled)

## Possible Failure Scenarios

**Thanos Receive Ingestor failure**: Thanos Router uses consistent hashing to redistribute incoming writes to healthy Ingestor replicas. Metrics continue flowing without data loss.

**Thanos Store Gateway failure**: Thanos Query continues serving recent metrics from Receive Ingestors (up to ~2 hours old). Historical queries beyond that timeframe will fail until the Thanos Store Gateway recovers.

**Prometheus failure**: Recent metrics stop flowing, but all historical data remains queryable via Thanos. Grafana dashboards show data up to the point of failure.

**Thanos Compact failure**: No immediate impact. Blocks accumulate without downsampling, increasing query latency and storage costs over time. Compaction resumes automatically when the component recovers.

**Thanos Query/Query Frontend failure**: Grafana cannot retrieve metrics. Prometheus continues remote-writing to Thanos, so no data loss occurs — only a temporary visualization gap.

**Azure Blob Storage outage**: Recent metrics (last ~2 hours) remain available from Thanos Receive Ingestors' local storage. Historical queries fail. Ingestors queue blocks for upload and retry when connectivity restores.

## Why This Architecture?

**Multi-cluster federation**:  
Both Prod and QA clusters remote-write to the same Thanos instance running in prod.  
Each cluster's Prometheus adds unique labels (cluster=prod/qa, environment=prod/qa) that enable filtering and aggregation across environments.  
QA writes to `https://thanos-receive.cloudandklir.com` (exposed via ingress), while prod writes directly to the in-cluster service.  
Adding additional clusters requires only configuring their Prometheus remote-write endpoint and external labels—no changes to storage or query layers.  
The single Grafana instance in Prod provides a unified view across all environments.

**Scalability**:  
Prometheus alone doesn't scale for multi-cluster or long retention. Thanos adds horizontal scalability and unlimited retention via object storage.

**Cost efficiency**:  
Azure Blob Storage is significantly cheaper than block storage for metrics. Downsampling reduces storage costs over time.

**No credential management**:  
Azure Workload Identity eliminates secret rotation burden. The cluster's OIDC issuer authenticates directly with Entra ID.

**Separation of concerns**:  
Each Thanos component has a single responsibility, making troubleshooting and scaling straightforward.

**GitOps native**:  
Native Kubernetes manifests integrate cleanly with Flux and Kustomize overlays, unlike complex Helm value overrides.

## Security Considerations

- All Thanos components run as non-root (UID 65534)
- Read-only root filesystems
- Dropped capabilities
- Azure authentication via federated identity tokens (no long-lived secrets)
- Secrets pulled from Azure Key Vault via External Secrets Operator
