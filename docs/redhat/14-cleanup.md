# Cleanup

This lab walks you through deleting all resources created during this tutorial.

All commands in this section should be run from the `jumpbox` unless otherwise specified.

## Stop Services

Stop Patroni, etcd (or Consul), and HAProxy services on the relevant nodes.

Stop Patroni on all cluster nodes:
```bash
for host in db1 db2 db3; do
  ssh root@${host} systemctl stop patroni
  ssh root@${host} systemctl disable patroni
  ssh root@${host} systemctl stop postgresql
  ssh root@${host} systemctl disable postgresql
  # If using Consul:
  ssh root@${host} systemctl stop consul || true
  ssh root@${host} systemctl disable consul || true
  # If using etcd:
  ssh root@${host} systemctl stop etcd || true
  ssh root@${host} systemctl disable etcd || true
  # Remove Patroni config
  ssh root@${host} rm -rf /etc/patroni
  ssh root@${host} rm -rf /var/lib/pgsql
  ssh root@${host} rm -rf /var/lib/postgresql
  ssh root@${host} rm -rf /var/lib/etcd
  ssh root@${host} rm -rf /var/lib/consul
  ssh root@${host} rm -f /etc/systemd/system/patroni.service /etc/systemd/system/etcd.service /etc/systemd/system/consul.service
  ssh root@${host} systemctl daemon-reload
  echo "Cleaned up ${host}"
done
```

Stop HAProxy on proxy nodes:
```bash
for host in proxy1 proxy2; do
  ssh root@${host} systemctl stop haproxy
  ssh root@${host} systemctl disable haproxy
  ssh root@${host} rm -f /etc/haproxy/haproxy.cfg
  ssh root@${host} rm -f /etc/systemd/system/haproxy.service
  ssh root@${host} systemctl daemon-reload
  echo "Cleaned up HAProxy on ${host}"
done
```

## Remove Packages

Remove Patroni, PostgreSQL, HAProxy, Consul/etcd, and dependencies from all nodes:
```bash
PG_VERSION=17 # Set this to your installed PostgreSQL version
for host in db1 db2 db3; do
  ssh root@${host} "dnf remove -y patroni postgresql${PG_VERSION}-server postgresql${PG_VERSION}-contrib etcd consul || true"
done
for host in proxy1 proxy2; do
  ssh root@${host} "dnf remove -y haproxy || true"
done
```

## Remove Generated Files from Jumpbox

Remove certificates, configuration files, and downloaded binaries from the `jumpbox` working directory:

```bash
rm -f machines.txt hosts
```

## Remove /etc/hosts Entries

Manually edit the `/etc/hosts` file on the `jumpbox` and each cluster node (`db1`, `db2`, `db3`, `proxy1`, `proxy2`) to remove the entries added during the tutorial (usually marked with `# Patroni The Hard Way`).

Example using `sed` (use with caution, backup `/etc/hosts` first):

```bash
# On jumpbox
sed -i.bak '/# Patroni The Hard Way/,/proxy2/d' /etc/hosts

# On all nodes
for host in db1 db2 db3 proxy1 proxy2; do
  ssh root@${host} "sed -i.bak '/# Patroni The Hard Way/,/proxy2/d' /etc/hosts"
done
```

## Delete Virtual Machines (If Applicable)

If you provisioned dedicated virtual or physical machines for this tutorial, you can now safely delete or deprovision them.

This concludes the Patroni The Hard Way tutorial cleanup.

If you are using Vagrant, you can run:

```bash
vagrant destroy -f
```
