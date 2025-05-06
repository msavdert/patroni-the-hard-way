# Setting up the Distributed Configuration Store (etcd)

In this lab, you will provision a Distributed Configuration Store (DCS) using etcd. Patroni relies on a DCS like etcd for leader election, storing cluster configuration, and maintaining cluster state. We will set up a 3-node etcd cluster, co-located on the same machines that will run PostgreSQL and Patroni (db1, db2, db3).

All commands in this section should be run from the `jumpbox`.

## Installing etcd on Oracle Linux 9

etcd will be used as the Distributed Configuration Store (DCS) for Patroni. The following steps will install etcd on all database and proxy nodes.

### Download and Install etcd

Run the following commands from the `jumpbox` to install etcd on all nodes:

```bash
for host in db1 db2 db3; do
  ssh -n root@${host} "dnf install -y etcd"
done
```

```bash
ssh db1 "etcd --version"
```

### Configure etcd

Create the etcd configuration file for each node by running the following loop from the jumpbox. This will configure etcd on all database nodes (`db1`, `db2`, `db3`):

```bash
for host in db1 db2 db3; do
  IP=$(grep ${host} machines.txt | cut -d' ' -f1)
  NAME=${host}
  CLUSTER_URL="db1=http://$(grep db1 machines.txt | cut -d' ' -f1):2380,db2=http://$(grep db2 machines.txt | cut -d' ' -f1):2380,db3=http://$(grep db3 machines.txt | cut -d' ' -f1):2380"
  cat << EOF | ssh root@${host} "cat > /etc/etcd/etcd.conf"
# [Member]
ETCD_LISTEN_PEER_URLS="http://$IP:2380"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:2379,http://$IP:2379"
ETCD_NAME="$NAME"
# [Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$IP:2380"
ETCD_INITIAL_CLUSTER="$CLUSTER_URL"
ETCD_ADVERTISE_CLIENT_URLS="http://$IP:2379"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-1"
ETCD_INITIAL_CLUSTER_STATE="new"
# [Tune]
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_INITIAL_ELECTION_TICK_ADVANCE="false"
ETCD_AUTO_COMPACTION_RETENTION="1"
EOF
done
```

Enable and start etcd:

```bash
for host in db1 db2 db3; do
  ssh -n root@${host} "systemctl daemon-reload && systemctl enable etcd --now"
done
```

Verify etcd is running:

```bash
for host in db1 db2 db3; do
  ssh -n root@${host} "systemctl status etcd --no-pager | grep Active"
done
```

Check etcd cluster health:

```bash
ssh db1 'ETCDCTL_API=3 etcdctl --write-out=table --endpoints="http://db1:2379,http://db2:2379,http://db3:2379" endpoint status'
ssh db1 'ETCDCTL_API=3 etcdctl --write-out=table --endpoints="http://db1:2379,http://db2:2379,http://db3:2379" endpoint health'
ssh db1 'ETCDCTL_API=3 etcdctl --write-out=table --endpoints="http://db1:2379,http://db2:2379,http://db3:2379" member list'
```

At this point, you have a functioning, secure 3-node etcd cluster ready for Patroni.

Next: [Configuring PostgreSQL](05-configuring-postgresql.md)
