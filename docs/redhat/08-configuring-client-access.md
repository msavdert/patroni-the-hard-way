# Configuring Client Access (HAProxy)

In this lab, you will set up HAProxy as a load balancer to provide a single endpoint for client applications to connect to the PostgreSQL cluster. HAProxy will use Patroni's REST API to perform health checks and direct connections only to the current leader node.

We will install and configure HAProxy on both `proxy1` and `proxy2` nodes for high availability. All operations will be performed from the `jumpbox`.

## Install HAProxy

Install HAProxy on both proxy1 and proxy2 nodes:

```bash
for host in proxy1 proxy2; do
  ssh root@${host} "dnf install -y haproxy"
done
```

## Configure HAProxy

First, retrieve the IP addresses of the PostgreSQL nodes:

```bash
PGNODE1=$(grep db1 machines.txt | cut -d' ' -f1)
PGNODE2=$(grep db2 machines.txt | cut -d' ' -f1)
PGNODE3=$(grep db3 machines.txt | cut -d' ' -f1)
PGPORT=5432
```

Now, use the following reference configuration to create the `/etc/haproxy/haproxy.cfg` file on both proxy1 and proxy2:

```bash
for host in proxy1 proxy2; do
  ssh root@${host} "cat > /etc/haproxy/haproxy.cfg" <<EOF
global
    maxconn 100
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /var/lib/haproxy/stats mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    mode               tcp
    log                global
    retries            2
    timeout queue      5s
    timeout connect    5s
    timeout client     30m
    timeout server     30m
    timeout check      15s

frontend prometheus
    bind *:8405
    mode http
    http-request use-service prometheus-exporter if { path /metrics }
    no log

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen read-write
    bind *:5000
    option httpchk OPTIONS /read-write
    http-check expect status 200
    default-server inter 3s fastinter 1s fall 3 rise 4 on-marked-down shutdown-sessions
    server db1 ${PGNODE1}:${PGPORT} maxconn 100 check port 8008
    server db2 ${PGNODE2}:${PGPORT} maxconn 100 check port 8008
    server db3 ${PGNODE3}:${PGPORT} maxconn 100 check port 8008

listen read-only
    balance roundrobin
    bind *:5001
    option httpchk OPTIONS /replica
    http-check expect status 200
    default-server inter 3s fastinter 1s fall 3 rise 4 on-marked-down shutdown-sessions
    server db1 ${PGNODE1}:${PGPORT} maxconn 100 check port 8008
    server db2 ${PGNODE2}:${PGPORT} maxconn 100 check port 8008
    server db3 ${PGNODE3}:${PGPORT} maxconn 100 check port 8008
EOF
done
```

## Start and Enable HAProxy

Start and enable the HAProxy service on both proxy nodes:

```bash
for host in proxy1 proxy2; do
  ssh root@${host} "systemctl restart haproxy && systemctl enable haproxy"
done
```

Check the status:

```bash
for host in proxy1 proxy2; do
  ssh root@${host} "systemctl status haproxy --no-pager"
done
```

## Access and Monitoring

- Applications can use `proxy1:5000` or `proxy2:5000` for read-write, and `proxy1:5001` or `proxy2:5001` for read-only connections.
- Access the HAProxy stats interface at `http://proxy1:7000` or `http://proxy2:7000`.
- Prometheus metrics are available at `http://proxy1:8405/metrics` or `http://proxy2:8405/metrics`.

---

Next: [Testing Failover](09-testing-failover.md)
