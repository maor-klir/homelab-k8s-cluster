# GitOps

GitOps is a way of implementing Continuous Deployment for cloud native applications.  
It focuses on a developer-centric experience when operating infrastructure, by using tools developers are already familiar with, including Git and Continuous Deployment tools.  
The core idea of GitOps is having a distributed Version Control System (VCS), most commonly Git, that always contains declarative descriptions of the infrastructure currently desired in the production environment and an automated process to make the production environment match the described state in the repository. It enables full automation that involves rapid updates and rollbacks.  

### Pull vs. Push Model Architecture 

It is important to mention that the GitOps methodology has two models in which it can operate and apply changes to the cluster environment: a _pull-based_ model and a _push-based_ model.

![Pull vs. Push Model Architecture](./assets/gitops-push-vs-pull.jpg)

#### Pull-based Model

In the pull-based model, a GitOps operator continuously monitors the desired state in a version-controlled Git repository for changes. 
When changes are detected, the operator fetches the updated configuration from the repository and applies it to the target environment.

**Advantages:**

- Better control and governance with reduced direct cluster access
- Easier auditing and compliance through automated reconciliation
- Enables self-service deployments by simply updating the codebase
- Enhanced security - no need to expose cluster credentials to CI/CD systems

**Purpose-built tools:** Argo CD, Flux

#### Push-based Model

In the push-based model, changes are pushed directly from the Git repository to the target environment, typically as part of a CI/CD pipeline. 
When changes are committed to the Git repository, the CI/CD pipeline triggers a deployment process that pushes the updated configuration to the target environment.

**Advantages:**

- Simpler initial setup and integration with existing CI/CD workflows
- Immediate feedback on deployment success or failure

**Disadvantages:**

- No automatic drift detection or self-healing capabilities
- Requires cluster credentials in CI/CD system, increasing security risk
- Changes may be less predictable and harder to audit
- Requires explicitly defining and maintaining deployment logic within the CI/CD pipeline configuration


**Common implementation:** CI/CD platforms like GitHub Actions, GitLab CI, Jenkins, or CircleCI configured to execute deployment commands directly

### OpenGitOps

The [OpenGitOps CNCF Sandbox project](https://github.com/open-gitops/project) is following the pull-based GitOps model and has defined its principles as follows:  

[GitOps Principles](https://opengitops.dev/):  

1. **Declarative** - A system managed by GitOps must have its desired state expressed declaratively.
2. **Versioned and Immutable** - Desired state is stored in a way that enforces immutability, versioning and retains a complete version history.
3. **Pulled Automatically** - Software agents automatically pull the desired state declarations from the source (Reconciliation Loop).
4. **Continuously Reconciled** - Software agents continuously observe actual system state and attempt to apply the desired state.

**In other words:**

- The entire system (infrastructure and applications alike) is described declaratively.
- The canonical desired system state is version controlled via Git.
- Approved changes (through a Pull Request) are automated and applied to the system.
- Software agents ensure correctness and alert upon recognizing drift from the desired state.

**It also highlights:**

- Transparency -  viewing Git commit history is publicly accessible and transparent to all
- Collaboration - the codebase can be shared across teams enabling joint projects
- Security hardening - Kubernetes API server access is not required since the changes are initiated from the remote Git codebase
- Ease of Rollbacks - changing back to a previous state can be applied easily by reverting to an older commit in the Git codebase.

#### Key Takeaways

1. The state of the cluster is always described in Git (infrastructure and application source code alike) 
2. There is no external system who has full access permissions to the cluster. The cluster polls the Git code base for changes and will pull changes and deployment information.
3. The GitOps controller is running in an endless loop (a reconciliation loop) and wishes to always match the Git codebase state with the cluster state.
4. An approval process can be implemented to apply a change made to the repository codebase via a pull request (PR) and subsequently  merging to the main branch.

**In my homelab I chose to go with a pull-based model, and specifically, with [Flux](https://fluxcd.io/) (commonly known as Flux CD)** 


## Selecting a Kubernetes Distribution

We want to strike a balance, a sweet spot if you will, between being able to easily install and configure settings manually and having the ability to add modular configurable options.  
Between being able to experiment and on the other hand, easily maintain the cluster in the long term.  

On top of that, we want to choose a Kubernetes distribution that is: 
- Stable and is able of running applications in a persistent manner
- Not bundled with add-ons. Not a vendor-locked opinionated way of handling extensions (a good example is Canonical's [MicroK8s](https://microk8s.io/))

**I opted for installing [K3s](https://k3s.io/) on an [Ubuntu Server](https://ubuntu.com/download/server) as my initial iteration.**  

A second Kubernetes environment includes security hardening of the cluster by transitioning to [Talos Linux](https://www.talos.dev/).  
The repository is available here: [homelab-k8s-cluster-2](https://github.com/maor-klir/homelab-k8s-cluster-2)

Here is a brief overview of the two aforementioned distributions:

### K3s

[K3s](https://k3s.io/) is packaged as a single binary that reduces the dependencies and steps needed to install, run, and auto-update a production Kubernetes cluster.
It strikes the perfect balance between easy installation and modular configurable options.

K3s also powers Rancher (by SUSE) - an enterprise Kubernetes management platform (can be referred as Kubernetes-as-a-Service).
With Rancher you can deploy and manage multiple K8s clusters at scale - from datacenter to cloud to edge.

### Talos Linux

[Talos Linux](https://www.talos.dev/) is a production-grade hardened Kubernetes distribution that is secure, immutable (the root filesystem is mounted as read-only), and minimal.
Talos Linux also removes host-level such as a Shell and SSH. 

All system management is done via an API, secured with Mutual TLS.
Talos abstracts some of K8s settings from the maintainer of the cluster.

## Flux

[Flux](https://fluxcd.io/) (commonly known as Flux CD) is an industry standard pull-based model GitOps tool.  
As mentioned before, I chose to fully commit to Flux while setting up this environment.  

I opted for the [monorepo](https://fluxcd.io/flux/guides/repository-structure/#monorepo) repository structure.  
In a monorepo approach you would store all your Kubernetes manifests in a single Git repository. The various environments specific configs are all stored in the same branch (e.g. `main`).  
My implementation utilizes a GitOps workflow for multiple environments using Kustomize overlays and Helm deployed as CRDs through the Flux operator.  
It it based on this example: [flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example)

## Secrets Management upon Bootstrapping the Cluster 

Flux natively integrates with SOPS through its Kustomize controller, enabling the secure storage and management of encrypted secrets within the Git repository in a GitOps workflow.  
The core of this integration is that the Flux Kustomize controller is capable of in-cluster decryption of SOPS-encrypted Kubernetes Secrets resources.  
Flux [recommends](https://fluxcd.io/flux/guides/mozilla-sops/#encrypting-secrets-using-age) combining SOPS with [age](https://github.com/FiloSottile/age) for encrypting secrets.  
Since it is an out-of-the-box option offered by Flux, I chose to initially utilize SOPS upon bootstrapping the cluster before moving to External Secrets Operator along with Azure Workload Identity (OIDC integration) and Azure Key Vault.  

## Enable External Access with Cloudflare Tunnels

A [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) enables us to reach our deployed applications from the internet without compromising security as a lightweight daemon (`cloudflared`) deployed on our cluster creates outbound-only connections to Cloudflare's global network.  
This functionality integrates flawlessly with managing DNS records on registered domains in Cloudflare Registrar (or transferred from another Domain Registrar).  
It is an elegant and relatively simple deployable solution.  