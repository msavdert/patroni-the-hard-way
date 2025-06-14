# Installing and Configuring Patroni

In this section, you will install Patroni and its dependencies on all database nodes (`db1`, `db2`, `db3`) and configure it to manage the PostgreSQL instances using the Consul cluster set up previously.

All commands should be run from the `jumpbox` unless otherwise specified.

## 1. Install Patroni and Dependencies

Install Patroni using `pip` along with necessary Python libraries for PostgreSQL and Consul interaction:

```bash
for host in db1 db2 db3; do
  ssh root@${host} "dnf install epel-release -y && \
    dnf install -y patroni patroni-etcd"
done
```

Verify the installation on one node:
```bash
ssh root@db1 patroni --version
```

## 2. Create Patroni Configuration File

Patroni uses a YAML configuration file. We will create a template and then generate a specific configuration for each node.

Now, create the configuration file (`/etc/patroni/patroni.yml`) on each node. This file tells Patroni how to connect to Consul, manage PostgreSQL, and expose its own API.

```bash
PG_VERSION=17 # Ensure this matches the installed PostgreSQL version

for host in db1 db2 db3; do
  IP=$(grep ${host} machines.txt | cut -d' ' -f1)
cat << EOF | ssh root@${host} "cat > /etc/patroni/patroni.yml"
scope: patroni-cluster
namespace: /service/
name: ${host}

restapi:
  listen: 0.0.0.0:8008
  connect_address: ${IP}:8008

etcd3:
    hosts:
    - db1:2379
    - db2:2379
    - db3:2379

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
        max_connections: 100
        shared_buffers: 256MB
        wal_level: replica
  initdb:
    - encoding: UTF8
    - locale: en_US.UTF-8
    - data-checksums
  pg_hba:
  - host replication replicator 0.0.0.0/0 scram-sha-256
  - host all all 0.0.0.0/0 scram-sha-256
  users:
    replicator:
      password: StrongReplicationPassword
      options:
        - replication

postgresql:
  listen: 0.0.0.0:5432
  connect_address: ${IP}:5432
  data_dir: /var/lib/pgsql/${PG_VERSION}/data
  bin_dir: /usr/pgsql-${PG_VERSION}/bin
  pgpass: /tmp/pgpass${host}
  authentication:
    replication:
      username: replicator
      password: StrongReplicationPassword
    superuser:
      username: postgres
      password: StrongAdminPassword

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

EOF
done
```

**Security Note:** The passwords in the configuration file are in plain text. In a production environment, consider using environment variables or a secrets management system to handle sensitive credentials.

## 4. Enable Patroni Service

Reload the systemd daemon and enable the Patroni service so it starts on boot. **Do not start the service yet.** The cluster bootstrapping will happen in the next step.

```bash
for host in db1 db2 db3; do
  ssh root@${host} "systemctl daemon-reload"
  ssh root@${host} "systemctl enable patroni"
done
```

At this point, Patroni is installed and configured on all nodes, and the systemd service is enabled but not started.

Next: [Bootstrapping the Patroni Cluster](07-bootstrapping-patroni.md)
