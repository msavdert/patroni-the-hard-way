# Setting up the Distributed Configuration Store (Consul)

In this lab, you will provision a Distributed Configuration Store (DCS) using Consul. Patroni relies on a DCS like Consul for leader election, storing cluster configuration, and maintaining cluster state. We will set up a 3-node Consul cluster, co-located on the same machines that will run PostgreSQL and Patroni (db1, db2, db3).

All commands in this section should be run from the `jumpbox`.

## Installing Consul on Oracle Linux 9

Consul will be used as the Distributed Configuration Store (DCS) for Patroni. The following steps will install Consul on all database and proxy nodes.

### Download and Install Consul

Run the following commands from the `jumpbox` to install Consul on all nodes:

```bash
CONSUL_VERSION="1.16.2"
while read IP FQDN HOST SUBNET; do
  ssh -n root@${HOST} "dnf install -y wget unzip && \
    wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -O /tmp/consul.zip && \
    unzip -o /tmp/consul.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/consul && \
    consul --version"
done < machines.txt
```

### Create Consul User and Directories

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n root@${HOST} "useradd --system --home /etc/consul.d --shell /bin/false consul; \
    mkdir -p /etc/consul.d /var/lib/consul; \
    chown -R consul:consul /etc/consul.d /var/lib/consul"
done < machines.txt
```

### Configure Consul

Create a Consul configuration file for each node. Example configuration for a server node (db1):

```json
{
  "server": true,
  "node_name": "db1",
  "datacenter": "dc1",
  "data_dir": "/var/lib/consul",
  "bind_addr": "<db1_ip>",
  "bootstrap_expect": 3,
  "client_addr": "0.0.0.0",
  "ui": true
}
```

Copy the configuration to `/etc/consul.d/consul.json` on each node, replacing `<db1_ip>` with the actual IP address.

### Create Consul Systemd Service

Create the following systemd unit file at `/etc/systemd/system/consul.service` on each node:

```ini
[Unit]
Description=Consul Agent
Requires=network-online.target
After=network-online.target

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

Enable and start Consul:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n root@${HOST} "systemctl daemon-reload && systemctl enable consul && systemctl start consul"
done < machines.txt
```

Verify Consul is running:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n root@${HOST} "systemctl status consul --no-pager | grep Active"
done < machines.txt
```

At this point, you have a functioning, secure 3-node Consul cluster ready for Patroni.

Next: [Configuring PostgreSQL](05-configuring-postgresql.md)
