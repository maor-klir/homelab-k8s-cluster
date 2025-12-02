# HCP Terraform Agents

HCP Terraform Agents allow HCP Terraform to communicate with isolated, private, or on-premises infrastructure.  
By deploying lightweight agents within a specific network segment, we can establish a simple connection between our environment and HCP Terraform, facilitating provisioning and management operations.  
This is useful for on-premises infrastructure, enterprise networking providers, and any systems in a protected enclave.  
The agent requires only outbound connectivity to HCP Terraform, enabling private networks to remain secure.  No special networking configuration or exceptions are typically needed.

Tutorial: https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-agents

**Note:** HCP Terraform Free Edition includes **one self-hosted agent**.

## General guidelines for the implementation
### Release archive checksum verification

HashiCorp signs all release archives with their GPG key. The following example uses Vault, but the same process applies to any HashiCorp product including `tfc-agent`:

```sh
# Import the public key as referenced above.
curl -s https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import

# Download the archive and signature files.
curl -Os https://releases.hashicorp.com/vault/1.15.2/vault_1.15.2_linux_amd64.zip
curl -Os https://releases.hashicorp.com/vault/1.15.2/vault_1.15.2_SHA256SUMS
curl -Os https://releases.hashicorp.com/vault/1.15.2/vault_1.15.2_SHA256SUMS.sig

# Verify the signature file is untampered.
gpg --verify vault_1.15.2_SHA256SUMS.sig vault_1.15.2_SHA256SUMS

# Verify the SHASUM matches the archive.
shasum -a 256 -c vault_1.15.2_SHA256SUMS --ignore-missing
```

### Unzip the archive on the designated machine

Copy the agent to the designated machine: (this folder has all related `tfc-agent` files)

```sh
scp -r tfc-agent ubuntu@192.168.0.200:~/
```

Unzip the archive:

```sh
unzip tfc-agent_1.25.1_linux_amd64.zip

ubuntu@test-ubuntu:~/tfc-agent$ ls -la
total 118632
drwxr-xr-x 2 ubuntu ubuntu     4096 Oct 26 17:31 .
drwxr-x--- 6 ubuntu ubuntu     4096 Oct 26 17:37 ..
-rw-rw-r-- 1 ubuntu ubuntu    10014 Oct 14 19:07 LICENSE.txt
-rwxrwxr-x 1 ubuntu ubuntu 20284712 Oct 14 19:07 tfc-agent
-rwxrwxr-x 1 ubuntu ubuntu 62723835 Oct 14 19:07 tfc-agent-core
-rw-r--r-- 1 ubuntu ubuntu      198 Oct 26 17:29 tfc-agent_1.25.1_SHA256SUMS
-rw-r--r-- 1 ubuntu ubuntu      566 Oct 26 17:29 tfc-agent_1.25.1_SHA256SUMS.sig
-rw-r--r-- 1 ubuntu ubuntu 38435028 Oct 26 17:29 tfc-agent_1.25.1_linux_amd64.zip
```

The `unzip` command extracts two individual binaries (`tfc-agent` and `tfc-agent-core`). These binaries must reside in the same directory for the agent to function properly.  

To start the agent and connect it to an HCP Terraform agent pool:

1. Retrieve the [token](https://developer.hashicorp.com/terraform/cloud-docs/agents/agent-pools#create-an-agent-pool) from the HCP Terraform agent pool you want to use.
2. Set the `TFC_AGENT_TOKEN` environment variable.
3. (Optional) Set the `TFC_AGENT_NAME` environment variable. This name is for your reference only. The agent ID appears in logs and API requests.

```sh
export TFC_AGENT_TOKEN=your-token
export TFC_AGENT_NAME=your-agent-name
./tfc-agent
```

Once complete, your agent and its status appear on the **Agents** page in the HCP Terraform UI. Workspaces can now use this agent pool for runs.


# My implementation

My implementation includes creating dedicated system user, systemd service file, and environment file.

## Create a systemd service file

### Set up a dedicated user and agent directory

```sh
# Create a dedicated system user (no home directory, no login shell)
sudo useradd --system --no-create-home --shell /bin/false tfc-agent

# Create a directory to store the agent binary and logs
sudo mkdir -p /opt/tfc-agent/bin
sudo mkdir -p /var/log/tfc-agent

# Set correct ownership for the agent and logs
sudo chown -R tfc-agent:tfc-agent /opt/tfc-agent
sudo chown -R tfc-agent:tfc-agent /var/log/tfc-agent
```

### Create a dedicated environment file

The `tfc-agent` must use environment variables in order to authenticate to HCP Terraform.

```sh
# Create the configuration directory
sudo mkdir -p /etc/tfc-agent

# Create the environment file
sudo vim /etc/tfc-agent/tfc-agent.env
```

```sh
# /etc/tfc-agent/tfc-agent.env

# HCP Terraform Agent Token (REQUIRED)
TFC_AGENT_TOKEN="<YOUR_AGENT_TOKEN>"

# HCP Terraform Agent Name
TFC_AGENT_NAME="<YOUR_AGENT_NAME>"

# Data Directory
TFC_AGENT_DATA_DIR="/var/lib/tfc-agent"
```

### Secure the environment file

```sh
sudo chmod 600 /etc/tfc-agent/tfc-agent.env
```

### Prepare the data directory for the agent

```sh
# Create the directory
sudo mkdir -p /var/lib/tfc-agent

# Set correct ownership for the agent
sudo chown -R tfc-agent:tfc-agent /var/lib/tfc-agent
```


### Create the systemd service file

Create the systemd unit file:

```sh
sudo vim /etc/systemd/system/tfc-agent.service
```

```ini
[Unit]
Description=HCP Terraform Agent
Documentation=https://developer.hashicorp.com/terraform/cloud-docs/agents
After=network.target

[Service]
# Load environment variables from the external file
EnvironmentFile=/etc/tfc-agent/tfc-agent.env

# Service settings
User=tfc-agent
Group=tfc-agent
WorkingDirectory=/opt/tfc-agent

# The main execution command
ExecStart=/opt/tfc-agent/bin/tfc-agent run

# Logging configuration
StandardOutput=append:/var/log/tfc-agent/tfc-agent.log
StandardError=append:/var/log/tfc-agent/tfc-agent.error.log

# Service management
Restart=always
RestartSec=5

# Security hardening (optional but recommended)
# Disable system calls not needed by the agent to reduce the attack surface
# SystemCallFilter=~@clock @debug @io @mount @obsolete @swap
# ProtectHome=true
# PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

### Enable and start the service

```sh
# Reload the systemd manager configuration
sudo systemctl daemon-reload

# Enable the service to start on boot and start the agent service immediately
sudo systemctl enable --now tfc-agent.service
```

### Verify status

```sh
# Check the service status
sudo systemctl status tfc-agent.service

# View the recent logs
sudo journalctl -u tfc-agent.service -f
```

### HCP Terraform Agent CLI options

https://developer.hashicorp.com/terraform/cloud-docs/agents/agents#cli-options