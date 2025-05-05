# Setting up the Distributed Configuration Store (Consul)

In this lab you will provision a Distributed Configuration Store (DCS) using Consul. Patroni relies on a DCS like Consul for leader election, storing cluster configuration, and maintaining the cluster state. We will set up a 3-node Consul cluster, co-located on the same machines that will run PostgreSQL and Patroni (db1, db2, db3).

The commands in this section should be run from the `jumpbox`.

## Download and Install Consul

Download the Consul binary and distribute it to each database node:

```bash
CONSUL_VERSION=1.20.4 # Use the latest stable version if available
ARCH=$(dpkg --print-architecture)
DOWNLOAD_URL=https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${ARCH}.zip

wget -q --show-progress -O consul.zip $DOWNLOAD_URL
unzip consul.zip
chmod +x consul

for host in db1 db2 db3; do
  scp consul root@${host}:/usr/local/bin/
  ssh root@${host} "mkdir -p /etc/consul.d /var/lib/consul"
done
```

## Create Consul Configuration

Create a Consul configuration file for each node. Each node will be a server in the Consul cluster.

```bash
for host in db1 db2 db3; do
  IP=$(grep ${host} machines.txt | cut -d' ' -f1)
  cat << EOF | ssh root@${host} "cat > /etc/consul.d/consul.hcl"
server = true
node_name = "${host}"
data_dir = "/var/lib/consul"
bind_addr = "${IP}"
client_addr = "0.0.0.0"
bootstrap_expect = 3
retry_join = [
  "db1",
  "db2",
  "db3"
]
ui = true
EOF

done
```

## Create Consul Systemd Service

Create a systemd unit file to manage the Consul service:

```bash
for host in db1 db2 db3; do
cat << EOF | ssh root@${host} "cat > /etc/systemd/system/consul.service"
[Unit]
Description=Consul Agent
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
done
```

## Enable and Start Consul

Reload systemd and start Consul on all nodes:

```bash
for host in db1 db2 db3; do
  ssh root@${host} "systemctl daemon-reload"
  ssh root@${host} "systemctl enable consul"
  ssh root@${host} "systemctl start consul"
done
```

## Verify the Consul Cluster

Check the status of the Consul service on each node:

```bash
for host in db1 db2 db3; do
  ssh root@${host} systemctl status consul --no-pager
  ssh root@${host} consul members
  ssh root@${host} consul operator raft list-peers
  # You should see all three nodes as members and peers
  # You can also access the Consul UI at http://<any-db-node-ip>:8500/ui
  # (if firewall allows)
done
```

At this point, you have a functioning, secure 3-node Consul cluster ready for Patroni.

Next: [Installing and Configuring PostgreSQL](05-configuring-postgresql.md)
