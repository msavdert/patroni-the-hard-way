# Testing Failover

In this lab, you will test the high availability capabilities of the Patroni cluster by simulating failures and observing the automatic failover process. You will also perform a manual switchover.

Commands in this section should be run from the `jumpbox`.

## Check Initial State

First, verify the current cluster state using `patronictl`:

```bash
ssh root@db1 "patronictl -c /etc/patroni/patroni.yml list patroni-cluster"
```

Note which node is the current `Leader`.

Verify that HAProxy is directing connections to the leader. Run the connection test multiple times:

```bash
for i in {1..3}; do
  PGPASSWORD=StrongAdminPassword psql -h proxy1 -p 5000 -U postgres -d postgres -c "SELECT pg_is_in_recovery(), inet_server_addr();"
  sleep 1
done
```

All connections should go to the same IP address (the leader's) and `pg_is_in_recovery` should be `f` (false).

Also, verify that HAProxy is directing connections to the replica. Run the connection test multiple times:

```bash
for i in {1..3}; do
  PGPASSWORD=StrongAdminPassword psql -h proxy1 -p 5001 -U postgres -d postgres -c "SELECT pg_is_in_recovery(), inet_server_addr();"
  sleep 1
done
```

All connections should go to the replica IP addresses and `pg_is_in_recovery` should be `t` (true).

## Simulate Leader Failure (Automatic Failover)

Let's simulate a failure of the current leader node. Identify the leader node from the `patronictl list` output (e.g., `node-0`).

Stop the Patroni service on the leader node:

```bash
# Replace node-0 with the actual leader node if different
ssh root@db1 systemctl stop patroni
```

Now, quickly observe the cluster state using `patronictl`. You might need to run it a few times.

```bash
watch 'ssh root@db1 "patronictl -c /etc/patroni/patroni.yml list patroni-cluster"'
```

You should see:

1.  The stopped node (`db1`) eventually disappear or show as unhealthy.
2.  One of the replicas (`db2` or `db3`) being promoted to `Leader`.
3.  The promotion process involves Patroni coordinating through etcd to elect a new leader from the available replicas.

Once a new leader is elected (this usually takes less than the `ttl` defined in `patroni.yml`, often around 10-30 seconds), verify client connections through HAProxy again:

```bash
for i in {1..3}; do
  PGPASSWORD=StrongAdminPassword psql -h proxy1 -p 5000 -U postgres -d postgres -c "SELECT pg_is_in_recovery(), inet_server_addr();"
  sleep 1
done
```

Connections should now be directed to the *new* leader's IP address, and `pg_is_in_recovery` should still be `f`.

Check the HAProxy stats page (`http://<jumpbox_ip>:8404`) to see the old leader marked as down and the new leader as active.

## Recover the Failed Node

Start the Patroni service on the node that was stopped (`node-0`):

```bash
ssh root@db1 systemctl start patroni
```

Observe the cluster state again:

```bash
watch 'ssh root@db1 "patronictl -c /etc/patroni/patroni.yml list patroni-cluster"'
```

The recovered node (`db1`) should rejoin the cluster as a `Replica`. Patroni might use `pg_rewind` (if configured and possible) to quickly bring the node back in sync, or it might need to re-initialize from the new leader if it diverged too much.

## Perform Manual Switchover

Patroni allows for planned, manual switchovers using `patronictl`. This is useful for maintenance or testing.

Identify the current leader and choose a replica to promote (e.g., promote `db2`).

```bash
# Check current leader
ssh root@db1 "patronictl -c /etc/patroni/patroni.yml list patroni-cluster"

# Initiate switchover (prompts for confirmation)
# Replace 'patroni-cluster' if you used a different scope
ssh root@db1 "patronictl -c /etc/patroni/patroni.yml switchover patroni-cluster --leader db3 --candidate db2 --force"
```

Follow the prompts. Patroni will:

1.  Gracefully shut down the current leader.
2.  Promote the chosen candidate replica.
3.  Reconfigure the old leader to become a replica of the new leader.

Verify the new cluster state:

```bash
ssh root@db1 "patronictl -c /etc/patroni/patroni.yml list patroni-cluster"
```

Verify client connections through HAProxy again:

```bash
PGPASSWORD=StrongAdminPassword psql -h proxy1 -p 5000 -U postgres -d postgres -c "SELECT pg_is_in_recovery(), inet_server_addr();"
```

Connections should now go to the newly promoted leader.

At this point, you have successfully tested both automatic failover and manual switchover, demonstrating the high availability provided by Patroni.

Next: [Smoke Test](10-smoke-test.md)
