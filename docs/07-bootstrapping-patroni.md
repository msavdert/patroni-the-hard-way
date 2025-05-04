# Bootstrapping the Patroni Cluster

In this lab, you will start the Patroni service on each node. Patroni will then use the configuration provided to connect to etcd, elect a leader, and initialize the PostgreSQL cluster (on the leader node) or set up replicas (on follower nodes).

Commands in this section should be run from the `jumpbox`.

## Start Patroni Service

It's generally recommended to start Patroni on one node first. This node will attempt to acquire the leader lock in etcd and initialize the PostgreSQL cluster (run `initdb`). Once the first node is up and running as the leader, you can start Patroni on the remaining nodes. These nodes will detect the existing cluster in etcd and configure themselves as replicas, bootstrapping from the leader.

Start Patroni on `node-0`:

```bash
ssh root@node-0 systemctl start patroni
```

Wait a minute or two for the service to start and potentially initialize the database cluster. You can monitor the logs on `node-0` to see the progress:

```bash
ssh root@node-0 journalctl -u patroni -f
```

Look for messages indicating successful initialization and acquiring the leader lock.

Once `node-0` is running as the leader, start Patroni on the other nodes:

```bash
ssh root@node-1 systemctl start patroni
ssh root@node-2 systemctl start patroni
```

Monitor the logs on `node-1` and `node-2` to see them join the cluster as replicas:

```bash
ssh root@node-1 journalctl -u patroni -f
# Look for messages about starting replication
```

```bash
ssh root@node-2 journalctl -u patroni -f
# Look for messages about starting replication
```

## Verify Cluster Status

Patroni provides a command-line tool, `patronictl`, to interact with the cluster. You need to point `patronictl` to your Patroni configuration file.

Install `patronictl` on the `jumpbox` (if you haven't already installed Patroni there) or run it from one of the cluster nodes.

Install on `jumpbox` (requires pip and dependencies):
```bash
# Ensure pip and dev tools are installed on jumpbox first
# apt-get update && apt-get install -y python3-pip python3-dev build-essential libpq-dev
pip install patroni[etcd3]
```

Create a minimal `patronictl.yml` configuration on the `jumpbox` to connect to etcd:

```bash
NODE0_IP=$(grep node-0 machines.txt | cut -d' ' -f1)
NODE1_IP=$(grep node-1 machines.txt | cut -d' ' -f1)
NODE2_IP=$(grep node-2 machines.txt | cut -d' ' -f1)

cat << EOF > patronictl.yml
etcd:
  hosts:
    - ${NODE0_IP}:2379
    - ${NODE1_IP}:2379
    - ${NODE2_IP}:2379
  protocol: https
  cacert: ca.crt
  # Use one of the node certs for client auth with patronictl
  cert: node-0-etcd.crt
  key: node-0-etcd.key
EOF
```

Now, use `patronictl` to view the cluster status:

```bash
patronictl -c patronictl.yml list patroni-cluster
```

You should see output similar to this, showing one leader and two replicas:

```text
+ Cluster: patroni-cluster (XXXXXXXXXXXXXX) ----+----+-----------+--------+---------+
| Member | Host   | Role    | State   | TL | Lag in MB |
+--------+--------+---------+---------+----+-----------+
| node-0 | node-0 | Leader  | running | 1  |           |
| node-1 | node-1 | Replica | running | 1  |         0 |
| node-2 | node-2 | Replica | running | 1  |         0 |
+--------+--------+---------+---------+----+-----------+
```

If all nodes show as `running` and one has the `Leader` role, the cluster has been successfully bootstrapped.

Next: [Configuring Client Access (HAProxy)](08-configuring-client-access.md)
