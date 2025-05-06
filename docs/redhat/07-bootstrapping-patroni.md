# Bootstrapping the Patroni Cluster

In this section, you will start the Patroni service on all database nodes (`db1`, `db2`, `db3`) to bootstrap the PostgreSQL high-availability cluster using Consul as the distributed configuration store.

## 1. Start Patroni on All Database Nodes

Run the following commands from the `jumpbox` to start Patroni on each database node:

```bash
for host in db1 db2 db3; do
  ssh root@${host} "systemctl start patroni"
done
```

## 2. Check Patroni and PostgreSQL Status

Verify that Patroni and PostgreSQL are running and healthy on all nodes:

```bash
for host in db1 db2 db3; do
  echo "Checking Patroni status on $host"
  ssh root@${host} "systemctl status patroni --no-pager | grep Active"
  echo "Checking PostgreSQL status on $host"
  ssh root@${host} "systemctl status postgresql-17 --no-pager | grep Active"
done
```

You should see `active (running)` for both Patroni and PostgreSQL services on each node.

## 3. Verify Cluster State

Check the cluster state using Patroni's REST API. You can run this from the `jumpbox`:

```bash
curl http://db1:8008/cluster

ssh root@db1 "patronictl -c /etc/patroni/patroni.yml list"
```

You should see JSON output showing the cluster members and their roles (one leader, two replicas).

## 4. Next Steps

Your Patroni cluster is now bootstrapped and running with Consul as the DCS. Continue with client access configuration in the next section.

Next: [Configuring Client Access (HAProxy)](08-configuring-client-access.md)
