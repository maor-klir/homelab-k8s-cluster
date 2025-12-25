# K3S Cluster Module

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.89 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.89.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_file.user_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.k3s_nodes](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_base_ip_address"></a> [base\_ip\_address](#input\_base\_ip\_address) | Base IP address for the VMs | `string` | `"192.168.0."` | no |
| <a name="input_control_plane_cores"></a> [control\_plane\_cores](#input\_control\_plane\_cores) | CPU cores for control plane nodes | `number` | `2` | no |
| <a name="input_control_plane_count"></a> [control\_plane\_count](#input\_control\_plane\_count) | Number of control plane nodes | `number` | `1` | no |
| <a name="input_control_plane_memory"></a> [control\_plane\_memory](#input\_control\_plane\_memory) | Memory allocation for control plane nodes in MB | `number` | `8192` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (qa, prod) | `string` | n/a | yes |
| <a name="input_gateway"></a> [gateway](#input\_gateway) | Default gateway for VMs | `string` | `"192.168.0.1"` | no |
| <a name="input_k3s_cluster_port"></a> [k3s\_cluster\_port](#input\_k3s\_cluster\_port) | K3s API server port | `number` | `6443` | no |
| <a name="input_k3s_public_key"></a> [k3s\_public\_key](#input\_k3s\_public\_key) | K3s user public key | `string` | n/a | yes |
| <a name="input_k3s_token"></a> [k3s\_token](#input\_k3s\_token) | K3s cluster token for joining nodes | `string` | n/a | yes |
| <a name="input_k3s_vm_dns"></a> [k3s\_vm\_dns](#input\_k3s\_vm\_dns) | DNS configuration for K3s VMs | <pre>object({<br/>    domain  = string<br/>    servers = list(string)<br/>  })</pre> | n/a | yes |
| <a name="input_k3s_vm_user"></a> [k3s\_vm\_user](#input\_k3s\_vm\_user) | K3s VM username | `string` | `"k3s"` | no |
| <a name="input_private_ssh_key"></a> [private\_ssh\_key](#input\_private\_ssh\_key) | The private SSH key content for accessing the Proxmox server | `string` | n/a | yes |
| <a name="input_pve_node_name"></a> [pve\_node\_name](#input\_pve\_node\_name) | The Proxmox Virtual Environment node names where the VMs will be created | `list(string)` | <pre>[<br/>  "pve-01",<br/>  "pve-02",<br/>  "pve-03"<br/>]</pre> | no |
| <a name="input_subnet_mask"></a> [subnet\_mask](#input\_subnet\_mask) | Subnet mask in CIDR notation | `string` | `"24"` | no |
| <a name="input_user_data_control_plane"></a> [user\_data\_control\_plane](#input\_user\_data\_control\_plane) | Cloud-init user data template for control-plane nodes | `string` | `"cloud-init/control-plane.yaml.tftpl"` | no |
| <a name="input_user_data_general"></a> [user\_data\_general](#input\_user\_data\_general) | Cloud-init general user data template file path | `string` | `"cloud-init/general.yaml.tftpl"` | no |
| <a name="input_user_data_worker"></a> [user\_data\_worker](#input\_user\_data\_worker) | Cloud-init user data template for worker nodes | `string` | `"cloud-init/worker.yaml.tftpl"` | no |
| <a name="input_vm_id_start"></a> [vm\_id\_start](#input\_vm\_id\_start) | Starting VM ID for the VMs | `number` | n/a | yes |
| <a name="input_worker_cores"></a> [worker\_cores](#input\_worker\_cores) | CPU cores for worker nodes | `number` | `2` | no |
| <a name="input_worker_count"></a> [worker\_count](#input\_worker\_count) | Number of worker nodes | `number` | `3` | no |
| <a name="input_worker_memory"></a> [worker\_memory](#input\_worker\_memory) | Memory allocation for worker nodes in MB | `number` | `8192` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_control_plane_nodes"></a> [control\_plane\_nodes](#output\_control\_plane\_nodes) | Map of control plane node details |
| <a name="output_worker_nodes"></a> [worker\_nodes](#output\_worker\_nodes) | Map of worker node details |
<!-- END_TF_DOCS -->
