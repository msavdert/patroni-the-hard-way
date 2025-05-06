# Cleanup

This lab walks through deleting the resources created during this tutorial.

Commands in this section should be run from the `jumpbox` unless otherwise specified.

## Stop Services

Stop Patroni, etcd, and HAProxy services on the relevant nodes.

Stop Patroni on all cluster nodes:
```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} systemctl stop patroni
  ssh root@${host} systemctl disable patroni
done
```

Stop etcd on all cluster nodes:
```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} systemctl stop etcd
  ssh root@${host} systemctl disable etcd
done
```

Stop HAProxy on the jumpbox (or wherever it was installed):
```bash
systemctl stop haproxy
systemctl disable haproxy
```

## Remove Packages and Configuration

Remove the installed packages and configuration files from each node.

Remove Patroni, PostgreSQL, etcd, and dependencies from cluster nodes:
```bash
PG_VERSION=16 # Ensure this matches the installed version
for host in node-0 node-1 node-2; do
  echo "Cleaning up ${host}..."
  # Remove Patroni via pip
  ssh root@${host} "pip uninstall -y patroni psycopg2 || true"
  # Remove PostgreSQL
  ssh root@${host} "apt-get purge -y postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} postgresql-common || true"
  ssh root@${host} "apt-get autoremove -y || true"
  # Remove etcd binaries
  ssh root@${host} "rm -f /usr/local/bin/etcd /usr/local/bin/etcdctl"
  # Remove configuration and data directories
  ssh root@${host} "rm -rf /etc/patroni /etc/etcd /var/lib/postgresql /var/lib/etcd"
  # Remove systemd files
  ssh root@${host} "rm -f /etc/systemd/system/patroni.service /etc/systemd/system/etcd.service"
done
ssh root@jumpbox systemctl daemon-reload # Reload systemd on jumpbox if needed
for host in node-0 node-1 node-2; do
  ssh root@${host} systemctl daemon-reload
done
```

Remove HAProxy from the jumpbox:
```bash
apt-get purge -y haproxy
apt-get autoremove -y
rm -f /etc/haproxy/haproxy.cfg
rm -f /etc/systemd/system/haproxy.service
systemctl daemon-reload
```

## Remove Generated Files from Jumpbox

Remove certificates, configuration files, and downloaded binaries from the `jumpbox` working directory.

```bash
# Change to the tutorial directory if not already there
# cd /root/patroni-the-hard-way

rm -f *.crt *.key *.csr *.srl *.kubeconfig *.yaml *.cnf
rm -f machines.txt hosts patronictl.yml
rm -rf downloads/
```

## Remove /etc/hosts Entries

Manually edit the `/etc/hosts` file on the `jumpbox` and each cluster node (`node-0`, `node-1`, `node-2`) to remove the entries added during the tutorial (usually marked with `# Patroni The Hard Way`).

Example using `sed` (use with caution, backup `/etc/hosts` first):

```bash
# On jumpbox
sed -i.bak '/# Patroni The Hard Way/,/node-2/d' /etc/hosts

# On cluster nodes
for host in node-0 node-1 node-2; do
  ssh root@${host} "sed -i.bak '/# Patroni The Hard Way/,/node-2/d' /etc/hosts"
done
```

## Delete Virtual Machines (If Applicable)

If you provisioned dedicated virtual or physical machines for this tutorial, you can now safely delete or deprovision them.

This concludes the Patroni The Hard Way tutorial cleanup.
