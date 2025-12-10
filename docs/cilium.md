# Why choose Cilium?

Selecting Cilium as the CNI for a Kubernetes cluster is the preferred choice for environments requiring high-performance, granular security, and integrated observability.  
Cilium leverages modern eBPF (extended Berkeley Packet Filter) technology to deliver a unified, high-performance networking and security platform.

## Performance and efficiency (eBPF)

Cilium utilizes eBPF programs directly in the Linux kernel to handle networking, load balancing, and security policies.
This approach is highly efficient because it bypasses the traditional Linux networking stack components like `iptables` and `kube-proxy`, which can become performance bottlenecks as a cluster grows.
The result is lower latency and higher throughput, especially in large-scale or high-traffic environments.

## Advanced security and policy enforcement

- Cilium elevates security far beyond standard Layer 3/Layer 4 controls. It enforces identity-aware network policies based on Kubernetes labels, ensuring security is tied to workload identity (pods, services) rather than ephemeral IP addresses.
- Cilium supports Layer 7 policies, enabling fine-grained control over specific application requests such as "Service A can only perform GET requests on `/api/v1/health` of Service B." This support is essential for zero-trust architectures.

## Unified control and observability

- Cilium offers a single, consolidated platform for networking by natively managing the CNI, service load balancing (replacing `kube-proxy`), and functioning as an Ingress or Gateway API controller. This centralized approach reduces operational overhead.
- Cilium is tightly integrated with Hubble, an eBPF-powered observability platform. Hubble provides deep, real-time visibility into network flow logs, L7 application requests (HTTP, DNS, etc.), and service dependency graphs, making troubleshooting significantly easier and more contextual than traditional IP and port logs.

## Native Ingress and Gateway API support

- Gateway API support: Cilium offers a conformant implementation of the modern [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/), a successor to the older Ingress API. The Gateway API is role-oriented, expressive, and extensible, making it better suited for complex and multi-tenant environments by clearly separating responsibilities between cluster operators and application developers.
- Integrated policy enforcement: Cilium's native Ingress/Gateway controller enables applying the same `CiliumNetworkPolicy` rules to traffic entering the cluster. The traffic is assigned an ingress identity, allowing policies to enforce security even on the first hop into application services.
