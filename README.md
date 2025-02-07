# :house::wheel_of_dharma: Homelab

## Introduction 

This GitHub repository contains all the documentation and configuration of my self-hosted Kubernetes homelab.

The purpose is first and foremost learning how to handle such equivalent environment in production running business-critical workloads.
And such, I treat this project with great care, attention to details, and seriousness. 

Having that in mind, forces one to take into account security, scalability, and backup strategies and adhere to industry standards best practices when provisioning different environments and maintaining the running workloads. 

Self-hosting also drives one to be accountable and responsible to take care of the ease of deployment and maintenance opreations over time, in other words - settings up proper automation and applying improvements as the environment thickens. 

That is where the GitOps operational framework kicks in and shines.

- [:house::wheel\_of\_dharma: Homelab](#housewheel_of_dharma-homelab)
  - [Introduction](#introduction)
  - [GitOps](#gitops)
    - [Pull vs. Push Architecture](#pull-vs-push-architecture)
      - [Pull-based Model](#pull-based-model)
      - [Push-based Model](#push-based-model)
    - [OpenGitOps](#opengitops)
      - [Key Takeaways](#key-takeaways)
  - [Selecting a Kubernetes Distribution](#selecting-a-kubernetes-distribution)
    - [K3s](#k3s)
    - [Talos Linux](#talos-linux)
  - [Flux](#flux)
  - [Secrets Management](#secrets-management)
  - [Enable Extrenal Access with Cloudflare Tunnels](#enable-extrenal-access-with-cloudflare-tunnels)
  - [Automated Image Updates](#automated-image-updates)
  - [Monitoring](#monitoring)
  - [Hardware](#hardware)
      - [Staging Cluster](#staging-cluster)
      - [Production Cluster](#production-cluster)
  - [Current Workloads](#current-workloads)
      - [Applications](#applications)
      - [Monitoring](#monitoring-1)
      - [Automated Image Updates](#automated-image-updates-1)


## GitOps

GitOps is a set of best practices where the entire code delivery process is controlled via a distributed Version Control System (VCS), most commonly Git. 
It applies to infrastructure and application code alike. It enables full automation that involves rapid updates and rollbacks.

### Pull vs. Push Architecture 

It is important to mention that the GitOps methodology has two models in which it can operate and apply changes to the cluster environment: pull-based model and push-based model.

![alt text](gitops-push-vs-pull.jpg)

#### Pull-based Model

In the pull-based model, a GitOps operator is continuously monitoring the desired state in a version-controlled Git repository for changes. 
When changes are detected, the operator fetches the updated configuration from the repository and applies it to the target environment.

It offers better control and governanace, easier auditing and compliance, and enables self-servicing the target environment by simply updating the codebase.

Industry standard tools include Argo CD and Flux.

#### Push-based Model

In the push-based model, changes are pushed directly from the Git repository to the target environment, typically as a part of a CI/CD pipeline. 
When changes are committed to the Git repository, the CI/CD pipeline triggers a deployment process that pushes the updated configuration to the target environment.

It offers simplicity and generally faster deployments in comparisson to a pull-based model but on the down side, changes may be less predictable, harder to audit, and implementation usually involves more manual steps or custom automation scripts.

Industry standard tools include GitHub Actions, GitLab CI, and Jenkins.

### OpenGitOps

The [OpenGitOps CNCF Sandbox project](https://github.com/open-gitops/project) is following the pull-based model GitOps methodology and has defined its principles as follows:

[GitOps Principles](https://opengitops.dev/):

1. Declarative - A system managed by GitOps must have its desired state expressed declaratively.
2. Versioned and Immutable - Desired state is stored in a way that enforces immutability, versioning and retains a complete version history.
3. Pulled Automatically - Software agents automatically pull the desired state declarations from the source (Reconciliation Loop).
4. Continuously Reconciled - Software agents continuously observe actual system state and attempt to apply the desired state.

**In other words:**

- The entire system (infrastructure and applications alike) is described declaratively.
- The canonical desired system state is version controlled via Git.
- Approved changes (through a Pull Request) are automated and applied to the system.
- Software agents ensure correctness and alert upon recognizing drift from the desired state.

**It also highlights:**

- Transparency -  viewing Git commit history is public accessible and transparent to all
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

We want to strike a balance, a sweet spot if you will, between being able to easily install and configure settings manually and having the ability to add modular configurable options. Between being able to experiment and on the other hand, easily maintain the cluster in the long term.

On top of that, we want to choose a Kubernetes distribution that is: 
- Stable and is able of running applications in a persistent manner
- Not bundled with add-ons. Not a vendor-locked opinionated way of handling extensions (a good example is Canonical's [MicroK8s](https://microk8s.io/))

**I opted for installing [K3s](https://k3s.io/) on an [Ubuntu Server](https://ubuntu.com/download/server) as my initial iteration.**

My next iteration will include security hardening of the cluster by transitioning to [Talos Linux](https://www.talos.dev/).

Here is a brief overview of the two aforementioned distributions:

### K3s

[K3s](https://k3s.io/) runs as single binary on the Linux operating system. This means it reduces dependencies and steps needed for installation, hence eases its bootstrapping process significantly. 
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
As mentioned before, I chose to fully commit to Flux while setting up this homelab.

I opted for the [Monorepo](https://fluxcd.io/flux/guides/repository-structure/#monorepo) repository structure.
In a monorepo approach you would store all your Kubernetes manifests in a single Git repository. The various environments specific configs are all stored in the same branch (e.g. `main`).

My implementation utilizes a Gitops workflow for multiple environments using Kustomize overlays and Helm deployed as CRDs through the Flux operator.

It it based on this example: [flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example)

## Secrets Management

Flux has the ability to decrypt secrets stored in Flux sources by itself, without the need of additional controllers installed in the cluster. 
The approach relies on keeping in Flux sources encrypted Kubernetes Secrets, which are decrypted on-demand with [SOPS](https://github.com/mozilla/sops), just before they are deployed into the target clusters.

Since it is an out-of-the-box option offered by Flux, I chose to initially utilize SOPS and probably later on move to a cloud-based offering secrets management tool such as Azure Key Vault or AWS Secrets Manager.

Flux [recommends](https://fluxcd.io/flux/guides/mozilla-sops/#encrypting-secrets-using-age) combining SOPS with [age](https://github.com/FiloSottile/age) for encrypting secrets. 


## Enable Extrenal Access with Cloudflare Tunnels

A [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) enables us to reach our deployed applications from the internet without compromising security as a lightweight daemon (cloudflared) deployed on our cluster creates outbound-only connections to Cloudflare's global network.

This functionality integrates flawlessly with managing DNS records on registered domains in Cloudflare Registrar (or transfered from another Domain Registrar).  

An elegant and relatively simple deployable solution.  

## Automated Image Updates

We would like to automate the process of scanning our deployed applications for available updates and
implement a workflow that will apply the changes to the latest version.

[Renovate](https://github.com/renovatebot/renovate) can help us with that task:

- Renovate will constantly check (in a predefined schedule) for new available images of our running containers in the cluster.
- Upon discovering that a new image version is available, it will create a pull request pending our approval.
- Renovate also offers us a rich overview of the release notes and further valuable details as part of the pull request.

## Monitoring

Obseravbilty tools are essential and highly important when provisioning and maintaining any modern environment.

The [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) is a widely-used tool, if not the defacto industry standard Kubernetes observabilty solution that is mostly recognized and adopted.

## Hardware

My current hardware setup includes:

#### Staging Cluster

Intended to serve as a playground for testing workloads, databases, secrets managements, and various toolings prior deploying to production.

- master-node-1: HP ProBook 650 G5 - Intel Core i5-8265U / 16GB RAM / 256GB SSD NVMe 

#### Production Cluster

...in the making...

## Current Workloads

#### Applications

- [linkding](https://github.com/sissbruecker/linkding) - a self-hosted bookmarks manager
- [Audiobookshelf](https://github.com/advplyr/audiobookshelf) - a self-hosted audiobook and podcast server

#### Monitoring

- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

#### Automated Image Updates

- [Renovate](https://github.com/renovatebot/renovate)