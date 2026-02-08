# K3s Cluster Load Balancer

This setup provides highly available access to the K3s Prod cluster API server through a redundant load balancing layer.  
The implementation uses three LXC container load balancer nodes (2 vCPUs/512MB RAM, Ubuntu Server 24.04 LTS) deployed on Proxmox VE via Terraform.  

HAProxy distributes Kubernetes API server traffic across the three control plane nodes running HA embedded etcd.  
Keepalived manages a shared virtual IP address that serves as the single, stable endpoint for cluster access.

## Setting up HAProxy and Keepalived

1. Install HAProxy and Keepalived on each LXC container load balancer node:

```sh
sudo apt install -y haproxy keepalived
```

2. Add the following to `/etc/haproxy/haproxy.cfg` on each node:

```ini
frontend k3s-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend k3s-backend

backend k3s-backend
    mode tcp
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s
    server k3s-prod-cp-01 192.168.0.201:6443 check
    server k3s-prod-cp-02 192.168.0.202:6443 check
    server k3s-prod-cp-03 192.168.0.203:6443 check
```

3. Add the following to `/etc/keepalived/keepalived.conf` on each node:

```nginx
global_defs {
  enable_script_security
  script_user root
}

vrrp_script chk_haproxy {
    script 'killall -0 haproxy' # faster than pidof
    interval 2
}

vrrp_instance haproxy-vip {
    interface eth0
    state <STATE> # MASTER on k3s-prod-lb-01, BACKUP on k3s-prod-lb-02 and k3s-prod-lb-03
    priority <PRIORITY> # 200 on k3s-prod-lb-01, 150 on k3s-prod-lb-02, 100 on k3s-prod-lb-03

    virtual_router_id 51

    virtual_ipaddress {
        192.168.0.210/24
    }

    track_script {
        chk_haproxy
    }
}
```

**Key points:**  

- The `priority` property determines failover order during VRRP election: the `k3s-prod-lb-01` node (priority = 200) is the active one by default, if it fails - `k3s-prod-lb-02` (priority = 150) takes over, if both fail - `k3s-prod-lb-03` (priority = 100) becomes active.
- The `state` property sets the initial role (`MASTER` or `BACKUP`) when `keepalived` starts: after startup, a VRRP election occurs and the instance with the highest priority becomes the actual master regardless of this setting.
- VRRP election: the automatic process where backup load balancers detect master failure (after missing 3+ advertisements) and select a new master based on priority values via multicast communication.
- The shared virtual IP address (`192.168.0.210`): serves as the cluster's fixed API endpoint. The shared VIP floats between load balancers; only the active master holds this address at any time.

4. Restart HAProxy and Keepalived on each node:

```sh
sudo systemctl restart haproxy.service
sudo systemctl restart keepalived.service
```
