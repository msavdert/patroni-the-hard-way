# Setting up the Distributed Configuration Store (Consul)

In this lab, you will provision a Distributed Configuration Store (DCS) using Consul. Patroni relies on a DCS like Consul for leader election, storing cluster configuration, and maintaining cluster state. We will set up a 3-node Consul cluster, co-located on the same machines that will run PostgreSQL and Patroni (db1, db2, db3).

All commands in this section should be run from the `jumpbox`.

## Installing Consul on Oracle Linux 9

Consul will be used as the Distributed Configuration Store (DCS) for Patroni. The following steps will install Consul on all database and proxy nodes.

### Download and Install Consul

Run the following commands from the `jumpbox` to install Consul on all nodes:

```bash
for host in db1 db2 db3; do
  ssh -n root@${host} "dnf install -y yum-utils && \
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    dnf -y install consul"
done
```

```bash
ssh db1 "consul --version"
```

### Configure Consul

Create the Consul configuration file for each node by running the following loop from the jumpbox. This will configure Consul on all database nodes (`db1`, `db2`, `db3`) in the required HCL format:

```bash
for host in db1 db2 db3; do
  IP=$(grep ${host} machines.txt | cut -d' ' -f1)
  cat << EOF | ssh root@${host} "cat > /etc/consul.d/consul.hcl"
datacenter       = "dc1"
node_name        = "${host}"
bind_addr        = "0.0.0.0"
client_addr      = "0.0.0.0"
data_dir        = "/opt/consul"
log_level        = "INFO"
server           = true
bootstrap_expect = 3
retry_join       = ["db1", "db2", "db3"]

ui_config {
  enabled = true
}
EOF
done
```

Enable and start Consul:

```bash
for host in db1 db2 db3; do
  ssh -n root@${host} "systemctl daemon-reload && systemctl enable consul --now"
done
```

Verify Consul is running:

```bash
for host in db1 db2 db3; do
  ssh -n root@${host} "systemctl status consul --no-pager | grep Active"
done
```

```bash
ssh -n root@db1 "consul members"
ssh -n root@db1 "consul operator raft list-peers"
```

At this point, you have a functioning, secure 3-node Consul cluster ready for Patroni.

Next: [Configuring PostgreSQL](05-configuring-postgresql.md)
