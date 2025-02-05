# Homelab

## Introduction 

This GitHub repository contains all the documentation and configuration of my self-hosted Kubernetes homelab.
The purpose is first and foremost learning how to handle such equivalent environment in production (i.e. being hired to do so for an employer).
Having that in mind will force one to take into account security, scalability, and backup strategies and adhere to industry best practices when provisioning the cluster and maintaining the running workloads. 
Self-hosting also makes you responsible to take care of the ease of deployment and maintenance over time, in other words - settings up proper automation. That is where the GitOps operational framework kicks in.

- [Homelab](#homelab)
  - [Introduction](#introduction)
  - [GitOps](#gitops)
  - [Selecting a Kubernetes Distribution:](#selecting-a-kubernetes-distribution)
      - [K3s](#k3s)
      - [Talos Linux](#talos-linux)


## GitOps

GitOps is a set of best practices where the entire code delivery process is controlled via a distributed Version Control System (VCS), most commonly Git. It applies to infrastructure and application code alike. It enables full automation that involves rapid updates and rollbacks.

[GitOps Principles](https://opengitops.dev/) as defined by the [OpenGitOps CNCF Sandbox project](https://github.com/open-gitops/project):

1. Declarative - A system managed by GitOps must have its desired state expressed declaratively.
2. Versioned and Immutable - Desired state is stored in a way that enforces immutability, versioning and retains a complete version history.
3. Pulled Automatically - Software agents automatically pull the desired state declarations from the source (Reconciliation Loop).
4. Continuously Reconciled - Software agents continuously observe actual system state and attempt to apply the desired state.

In other words:

- The entire system (infrastructure and applications alike) is described declaratively.
- The canonical desired system state is version controlled via Git.
- Approved changes (through a Pull Request) are automated and applied to the system.
- Software agents ensure correctness and alert upon recognizing drift from the desired state.

GitOps methodology also highlights:

- Transparency -  viewing Git commit history is public accessible and transparent to all
- Collaboration - the codebase can be shared across teams enabling joint projects
- Security hardening - Kubernetes API server access is not required since the changes are initiated from the remote Git codebase
- Ease of Rollbacks - changing back to a previous state can be applied easily by reverting to an older commit in the Git codebase.

 Key Takeaways:

1. The state of the cluster is always described in Git (infrastructure and application source code alike) 
2. There is no external system who has full access permissions to the cluster. The cluster polls the Git code base for changes and will pull changes and deployment information.
3. The GitOps controller is running in an endless loop (a reconciliation loop) and wishes to always match the Git codebase state with the cluster state.
4. An approval process can be implemented to apply a change made to the repository codebase via a pull request (PR) and subsequently  merging to the main branch.

## Selecting a Kubernetes Distribution:

We want to strike a balance, a sweet spot if you will, between being able to easily install and configure settings manually and having the ability to add modular configurable options. Between being able to experiment and on the other hand, easily maintain the cluster in the long term.
On top of that, we want to choose a Kubernetes distribution that is: 
- Stable and is able of running applications in a persistent manner
- Not bundled with add-ons. Not a vendor-locked opinionated way of handling extensions (a good example is Canonical's [MicroK8s](https://microk8s.io/))

I chose to opt for installing K3s on an [Ubuntu Server](https://ubuntu.com/download/server) as my initial iteration. 
My next iteration will include future security hardening of the cluster by transitioning to Talos Linux.
Here is a brief overview of the two aforementioned distributions:
#### [K3s](https://k3s.io/)

K3s runs as single binary on the Linux operating system. This means it reduces dependencies and steps needed for installation, hence eases its bootstrapping process significantly. It strikes the perfect balance between easy installation and modular configurable options.
K3s also powers Rancher (by Suse) - an enterprise Kubernetes management platform (can be referred as Kubernetes-as-a-Service).
With Rancher you can deploy and manage multiple K8s clusters at scale - from datacenter to cloud to edge.

#### [Talos Linux](https://www.talos.dev/)

A production-grade hardened Kubernetes distribution that is secure, immutable (the root filesystem is mounted as read-only), and minimal.
Talos Linux also removes host-level such as a Shell and SSH. All system management is done via an API, secured with Mutual TLS.
Talos abstracts some of K8s settings from the maintainer of the cluster.
