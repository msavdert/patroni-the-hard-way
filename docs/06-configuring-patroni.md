# Installing and Configuring Patroni

In this lab, you will install Patroni and its dependencies on each cluster node (`node-0`, `node-1`, `node-2`) and configure it to manage the PostgreSQL instances using the etcd cluster set up previously.

Commands in this section should be run from the `jumpbox`.

## Install Patroni and Dependencies

Install Patroni using `pip` along with necessary Python libraries for PostgreSQL and etcd interaction.

```bash
for host in node-0 node-1 node-2; do
  # Install pip and build dependencies
  ssh root@${host} "apt-get update"
  ssh root@${host} "apt-get install -y python3-pip python3-dev python3-venv build-essential libpq-dev python3-setuptools"

  # Install Patroni and required libraries
  ssh root@${host} "pip install wheel patroni[etcd3] psycopg[binary]"
done
```

Verify the installation on one node:
```bash
ssh root@node-0 patroni --version
```

## Create Patroni Configuration File

Patroni uses a YAML configuration file. We will create a template and then generate a specific configuration for each node.

Create the directory for Patroni configuration on each node:
```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} "mkdir -p /etc/patroni"
done
```

Now, create the configuration file (`/etc/patroni/patroni.yml`) on each node. This file tells Patroni how to connect to etcd, manage PostgreSQL, and expose its own API.

We will use the etcd certificates generated in the previous step for secure communication.

```bash
PG_VERSION=16 # Ensure this matches the installed PostgreSQL version

# Get node IPs for etcd connection
NODE0_IP=$(grep node-0 machines.txt | cut -d' ' -f1)
NODE1_IP=$(grep node-1 machines.txt | cut -d' ' -f1)
NODE2_IP=$(grep node-2 machines.txt | cut -d' ' -f1)

while read IP FQDN HOST; do

# Note: Adjust user/password/database names as desired.
# Patroni needs superuser access initially to bootstrap.
# The replication user will be created by Patroni during bootstrap.

cat << EOF | ssh root@${HOST} "cat > /etc/patroni/patroni.yml"
scope: patroni-cluster # Name of the cluster
namespace: /patroni/    # Base path in etcd

name: ${HOST}          # Unique name for this node

restapi:
  listen: ${IP}:8008
  connect_address: ${IP}:8008

etcd:
  hosts:
    - ${NODE0_IP}:2379
    - ${NODE1_IP}:2379
    - ${NODE2_IP}:2379
  protocol: https
  cacert: /etc/etcd/ca.crt
  cert: /etc/etcd/${HOST}-etcd.crt # Reuse etcd node cert for client auth
  key: /etc/etcd/${HOST}-etcd.key

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        # Standard PostgreSQL parameters
        max_connections: 100
        shared_buffers: 256MB
        wal_level: replica
        # Add other parameters as needed
  initdb:
    - encoding: UTF8
    - locale: en_US.UTF-8
    - data-checksums
  # Define users Patroni should create during initdb
  # The replication user MUST have the REPLICATION attribute.
  users:
    admin:
      password: StrongAdminPassword
      options:
        - createrole
        - createdb
    replicator:
      password: StrongReplicationPassword
      options:
        - replication

postgresql:
  listen: ${IP}:5432
  connect_address: ${IP}:5432
  data_dir: /var/lib/postgresql/${PG_VERSION}/main # Must match PG installation
  bin_dir: /usr/lib/postgresql/${PG_VERSION}/bin # Must match PG installation
  pgpass: /tmp/pgpass${HOST} # Patroni manages this file
  authentication:
    replication:
      username: replicator
      password: StrongReplicationPassword
    superuser:
      username: admin # Should match a user defined in bootstrap.users
      password: StrongAdminPassword
  # Callbacks can be added here if needed
EOF

  # Set permissions (adjust if running Patroni as non-root)
  ssh root@${HOST} "chown -R root:root /etc/patroni && chmod 600 /etc/patroni/patroni.yml"

done < machines.txt
```

**Important Security Note:** The passwords in the configuration file are in plain text. In a production environment, consider using environment variables or a secrets management system to handle sensitive credentials.

## Create Patroni Systemd Service

Create a systemd unit file to manage the Patroni service.

```bash
for host in node-0 node-1 node-2; do
cat << EOF | ssh root@${host} "cat > /etc/systemd/system/patroni.service"
[Unit]
Description=Patroni PostgreSQL High-Availability Manager
After=network.target etcd.service
Requires=etcd.service

[Service]
User=root # Or a dedicated 'patroni' user if created
Group=root # Or a dedicated 'patroni' group
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
Restart=on-failure
KillMode=process
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF
done
```

## Enable Patroni Service

Reload the systemd daemon and enable the Patroni service so it starts on boot. **Do not start the service yet.** The cluster bootstrapping will happen in the next step.

```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} "systemctl daemon-reload"
  ssh root@${host} "systemctl enable patroni"
done
```

At this point, Patroni is installed and configured on all nodes, and the systemd service is enabled but not started.

Next: [Bootstrapping the Patroni Cluster](07-bootstrapping-patroni.md)
