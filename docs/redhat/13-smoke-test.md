# Smoke Test

In this lab, you will perform a few basic tests to ensure the Patroni cluster and HAProxy are functioning correctly. This includes writing data to the leader and reading it from a replica.

Commands in this section should be run from the `jumpbox`.

## Verify Cluster and HAProxy Status

First, ensure the cluster is healthy and HAProxy is routing to the leader.

Check Patroni cluster status:

```bash
ssh root@db1 "patronictl -c /etc/patroni/patroni.yml list patroni-cluster"
```

Ensure one node is `Leader` and others are `Replica`, all in `running` state.

Check HAProxy connection:

```bash
PGPASSWORD=StrongAdminPassword psql -h proxy1 -p 5000 -U postgres -d postgres -c "SELECT pg_is_in_recovery(), inet_server_addr();"
```

This should connect to the leader (returns `f` for recovery and the leader's IP).

## Write Data to Leader

Connect to the cluster via HAProxy (which directs you to the leader) and perform some write operations.

```bash
# Connect using psql via HAProxy
PGPASSWORD=StrongAdminPassword psql -h proxy1 -p 5000 -U postgres -d postgres
```

Inside the `psql` session, run the following SQL commands:

```sql
-- Create a simple test table
CREATE TABLE smoke_test (id SERIAL PRIMARY KEY, message TEXT, created_at TIMESTAMPTZ DEFAULT NOW());

-- Insert some data
INSERT INTO smoke_test (message) VALUES ('Hello Patroni!');
INSERT INTO smoke_test (message) VALUES ('Testing HA setup.');

-- Verify data on leader
SELECT * FROM smoke_test;

-- Exit psql
\q
```

You should see the two inserted rows.

## Read Data from Replica

Now, let's verify that the data written to the leader has been replicated to a replica node. We need to connect directly to a replica's PostgreSQL instance.

Connect directly to the replica's PostgreSQL replica port (default 5001):

```bash
# Connect directly to the replica IP
PGPASSWORD=StrongAdminPassword psql -h proxy1 -p 5001 -U postgres -d postgres
```

Inside the `psql` session on the replica, run the following SQL commands:

```sql
-- Verify connection is to replica (should return 't')
SELECT pg_is_in_recovery();

-- Verify data replication
SELECT * FROM smoke_test;

-- Attempt a write operation (should fail on a read-only replica)
INSERT INTO smoke_test (message) VALUES ('This should fail.');
-- ERROR:  cannot execute INSERT in a read-only transaction

-- Exit psql
\q
```

You should see the same two rows that were inserted on the leader, confirming that streaming replication is working. The attempted INSERT should fail because replicas are typically read-only.

## Check HAProxy Stats (Optional)

Access the HAProxy stats page in your browser: `http://<jumpbox_ip>:8404`. Verify that the leader node is marked UP in the `postgresql_backend` section and the replicas are also UP (though HAProxy won't send connections to them due to the health check).

If these tests pass, your basic Patroni HA cluster is operational and correctly configured with HAProxy for client connections.

Next: [Cleaning Up](11-cleanup.md)
