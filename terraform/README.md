# Project K3s on Proxmox VE

## What am I trying to achieve?

- create a 3-node Kubernetes cluster (1 control plane, 2 worker nodes)
- use K3s as my Kubernetes flavour
- use Fedora Server as the base Linux OS
- provision the VMs using Terraform
- use cloud-init to configure the initial setup of the VMs
- ~~create a Terraform remote backend hosted on AWS~~
