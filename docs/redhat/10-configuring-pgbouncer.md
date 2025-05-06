# Configuring PgBouncer

PgBouncer is a lightweight connection pooler for PostgreSQL. It helps manage a large number of client connections to a smaller number of actual PostgreSQL server connections, reducing resource consumption and improving performance, especially for applications that open and close connections frequently.

In this Patroni setup, PgBouncer can be configured to sit between the applications and HAProxy/PostgreSQL to further optimize database connections.

## Installation

1.  **Install PgBouncer:**
```bash
for host in proxy1 proxy2; do
  ssh root@${host} "dnf install epel-release -y && \
    dnf install -y pgbouncer"
done
```

2.  **Enable the PgBouncer service:**
```bash
for host in proxy1 proxy2; do
  ssh root@${host} "systemctl enable --now pgbouncer"
done
```

Check the status:

```bash
for host in proxy1 proxy2; do
  ssh root@${host} "systemctl status haproxy --no-pager"
done
```

## Configuration

... more configuration details will be added in subsequent steps ...