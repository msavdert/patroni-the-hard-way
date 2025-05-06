# Configuring Client Access (HAProxy)

In this lab, you will set up HAProxy as a load balancer to provide a single endpoint for client applications to connect to the PostgreSQL cluster. HAProxy will use Patroni's REST API to perform health checks and direct connections only to the current leader node.

We will install and configure HAProxy on the `jumpbox` for simplicity, but in a production environment, you would typically run HAProxy on dedicated machines for high availability.

Commands in this section should be run from the `jumpbox`.

## Install HAProxy

Install the HAProxy package:

```bash
apt-get update
apt-get install -y haproxy
```

## Configure HAProxy

Create the HAProxy configuration file `/etc/haproxy/haproxy.cfg`. This configuration defines a frontend for incoming PostgreSQL connections and a backend consisting of our Patroni nodes.

First, gather the IP addresses of the Patroni nodes:
```bash
NODE0_IP=$(grep node-0 machines.txt | cut -d' ' -f1)
NODE1_IP=$(grep node-1 machines.txt | cut -d' ' -f1)
NODE2_IP=$(grep node-2 machines.txt | cut -d' ' -f1)
```

Now, create the configuration file. Replace the existing content of `/etc/haproxy/haproxy.cfg` with the following:

```bash
cat << EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend postgresql_frontend
    bind *:5000
    mode tcp
    option tcplog
    default_backend postgresql_backend

backend postgresql_backend
    mode tcp
    option pgsql-check user postgres # Basic check, not leader-aware
    # Use httpchk for leader check via Patroni API
    option httpchk GET /primary HTTP/1.0\r\nHost:\ localhost
    # Note: If Patroni API requires auth or HTTPS, adjust httpchk options
    # Example for HTTPS (requires HAProxy compiled with SSL and certs configured):
    # http-check expect status 200
    # server node-0 ${NODE0_IP}:5432 check port 8008 ssl verify none check-ssl inter 5s fall 3 rise 2

    # Simple HTTP check (adjust port if Patroni API is different)
    http-check expect status 200
    server node-0 ${NODE0_IP}:5432 check port 8008 inter 5s fall 3 rise 2
    server node-1 ${NODE1_IP}:5432 check port 8008 inter 5s fall 3 rise 2
    server node-2 ${NODE2_IP}:5432 check port 8008 inter 5s fall 3 rise 2

listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /
    stats refresh 10s
    stats admin if TRUE # Be careful with this in production
EOF
```

**Explanation:**

*   **frontend postgresql_frontend**: Listens on port `5000` for incoming TCP connections.
*   **backend postgresql_backend**: Defines the group of PostgreSQL servers.
*   **option httpchk GET /primary**: Configures HAProxy to send an HTTP GET request to the `/primary` endpoint of the Patroni REST API (running on port `8008` by default) on each node.
*   **http-check expect status 200**: HAProxy expects an HTTP 200 OK response. Patroni returns 200 only if the node is the leader (primary).
*   **server node-X ... check port 8008**: Defines each backend server, telling HAProxy to perform the health check against port `8008`.
*   **listen stats**: Enables the HAProxy statistics page on port `8404` (useful for monitoring).

**Note:** The `/primary` endpoint is generally preferred over `/leader` as it checks if PostgreSQL is running and accepting connections, not just if Patroni holds the leader lock. If your Patroni API requires authentication or uses HTTPS, you will need to adjust the `httpchk` options and potentially configure certificates within HAProxy.

## Start and Enable HAProxy

Restart HAProxy to apply the new configuration and enable it to start on boot:

```bash
systemctl restart haproxy
systemctl enable haproxy
```

Check the status:
```bash
systemctl status haproxy --no-pager
```

## Verify Client Access

Now, you should be able to connect to the PostgreSQL cluster leader via the HAProxy frontend on the `jumpbox` (port 5000). Use the `psql` client and the credentials defined in the Patroni configuration (`admin`/`StrongAdminPassword`).

```bash
# Ensure postgresql-client is installed on jumpbox: apt-get install -y postgresql-client-16
PGPASSWORD=StrongAdminPassword psql -h localhost -p 5000 -U admin -d postgres -c "SELECT pg_is_in_recovery();"
```

This command should connect successfully, and the query should return `f` (false), indicating you are connected to the leader node.

You can also check the HAProxy stats page by browsing to `http://<jumpbox_ip>:8404`.

At this point, client applications can use `jumpbox_ip:5000` as their connection endpoint, and HAProxy will ensure they are routed to the current PostgreSQL leader managed by Patroni.

Next: [Testing Failover](09-testing-failover.md)
