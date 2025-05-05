# Setting up the Distributed Configuration Store (Consul)

In this lab, you will provision a Distributed Configuration Store (DCS) using Consul. Patroni relies on a DCS like Consul for leader election, storing cluster configuration, and maintaining cluster state. We will set up a 3-node Consul cluster, co-located on the same machines that will run PostgreSQL and Patroni (db1, db2, db3).

All commands in this section should be run from the `jumpbox`.

## Download and Install Consul (Automated)

The following commands will automatically install the Consul binary on db1, db2, and db3:

```bash
for host in db1 db2 db3; do
  ssh root@$host "wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && \
    sudo apt update && sudo apt install -y consul"
done
```

## Create Consul Configuration

Create the Consul configuration file for each node as follows:

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

ssh root@${host} "mkdir -p /var/lib/consul && \
chown -R consul:consul /var/lib/consul"

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

Check the status of the Consul service and verify cluster membership on each node:

```bash
for host in db1 db2 db3; do
  ssh root@${host} systemctl status consul --no-pager | grep "Active"
  ssh root@${host} consul members
  ssh root@${host} consul operator raft list-peers
  # You should see all three nodes as members and peers
  # You can also access the Consul UI at http://<any-db-node-ip>:8500/ui
  # (if firewall allows)
done
```

At this point, you have a functioning, secure 3-node Consul cluster ready for Patroni.

Next: [Installing and Configuring PostgreSQL](05-configuring-postgresql.md)
