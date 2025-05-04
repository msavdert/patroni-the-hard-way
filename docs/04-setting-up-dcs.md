# Setting up the Distributed Configuration Store (etcd)

In this lab you will provision a Distributed Configuration Store (DCS) using etcd. Patroni relies on a DCS like etcd for leader election, storing cluster configuration, and maintaining the cluster state. We will set up a 3-node etcd cluster, co-located on the same machines that will run PostgreSQL and Patroni.

We will also secure etcd communication using TLS certificates generated from a self-signed Certificate Authority (CA). The commands in this section should be run from the `jumpbox`.

## Certificate Authority

In this section you will provision a Certificate Authority that will be used to generate TLS certificates for the etcd cluster members. Setting up a CA and generating certificates using `openssl` can be complex. To streamline this lab, we'll use the provided `ca.conf` openssl configuration file.

Take a moment to review the `ca.conf` configuration file if you wish:

```bash
cat ca.conf
```

Generate the CA private key and root certificate:

```bash
{
  openssl genrsa -out ca.key 4096
  openssl req -x509 -new -sha512 -noenc \
    -key ca.key -days 3653 \
    -subj "/CN=Patroni CA" \
    -out ca.crt
}
```

Results:

```txt
ca.crt ca.key
```

## Generate etcd Server and Peer Certificates

In this section you will generate server certificates for each etcd node. These certificates will be used for client-to-server communication (e.g., Patroni connecting to etcd) and server-to-server (peer) communication within the etcd cluster.

We need to define the IP addresses and hostnames for the certificates. Create temporary openssl config snippets for each node.

```bash
while read IP FQDN HOST; do
cat << EOF | tee ${HOST}-openssl.cnf
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${HOST}
DNS.2 = ${FQDN}
IP.1 = ${IP}
IP.2 = 127.0.0.1
EOF
done < machines.txt
```

Generate the certificates and private keys for each etcd node:

```bash
for host in node-0 node-1 node-2; do
  openssl genrsa -out "${host}-etcd.key" 4096

  openssl req -new -key "${host}-etcd.key" -sha256 \
    -subj "/CN=${host}" \
    -config "${host}-openssl.cnf" \
    -out "${host}-etcd.csr"

  openssl x509 -req -days 3653 -in "${host}-etcd.csr" \
    -CA "ca.crt" -CAkey "ca.key" \
    -CAcreateserial \
    -extensions v3_req -extfile "${host}-openssl.cnf" \
    -sha256 \
    -out "${host}-etcd.crt"

  rm "${host}-openssl.cnf" "${host}-etcd.csr"
done
```

The results of running the above commands will generate a private key and signed SSL certificate for each etcd node. You can list the generated files:

```bash
ls -1 node-*-etcd.crt node-*-etcd.key ca.crt ca.key ca.srl
```

## Distribute Certificates and Binaries

Copy the CA certificate and the node-specific etcd certificates/keys to each node.

```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} mkdir -p /etc/etcd/
  scp ca.crt ${host}-etcd.crt ${host}-etcd.key root@${host}:/etc/etcd/
done
```

Download and distribute the etcd binaries (etcd, etcdctl) to each node. Adjust the version and architecture as needed.

```bash
{
  ETCD_VER=v3.5.14 # Choose a recent stable version
  ARCH=$(dpkg --print-architecture)
  DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download

  # Download if not already present in downloads dir
  if [ ! -f "downloads/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz" ]; then
    wget -q --show-progress -P downloads \
      ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz
  fi

  tar -xzf downloads/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz \
    -C downloads --strip-components=1 etcd-${ETCD_VER}-linux-${ARCH}/etcd etcd-${ETCD_VER}-linux-${ARCH}/etcdctl

  chmod +x downloads/etcd downloads/etcdctl

  # Distribute binaries
  for host in node-0 node-1 node-2; do
    ssh root@${host} mkdir -p /usr/local/bin/
    scp downloads/etcd downloads/etcdctl root@${host}:/usr/local/bin/
  done
}
```

## Configure and Start etcd

In this section, you will configure and start the etcd service on each node using systemd.

Retrieve the internal IP addresses for the initial cluster string:
```bash
INITIAL_CLUSTER=""
while read IP FQDN HOST; do
  INITIAL_CLUSTER+="${HOST}=https://${IP}:2380,"
done < machines.txt
INITIAL_CLUSTER=${INITIAL_CLUSTER%,} # Remove trailing comma
echo $INITIAL_CLUSTER
```

Create the etcd systemd unit file on each node. This uses the certificates generated earlier and defines the cluster members.

```bash
while read IP FQDN HOST; do

cat << EOF | ssh root@${HOST} "cat > /etc/systemd/system/etcd.service"
[Unit]
Description=etcd distributed key-value store
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
User=root
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${HOST} \\
  --data-dir /var/lib/etcd \\
  --initial-advertise-peer-urls https://${IP}:2380 \\
  --listen-peer-urls https://${IP}:2380 \\
  --listen-client-urls https://${IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${IP}:2379 \\
  --initial-cluster-token etcd-cluster-patroni \\
  --initial-cluster ${INITIAL_CLUSTER} \\
  --initial-cluster-state new \\
  --client-cert-auth \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --cert-file=/etc/etcd/${HOST}-etcd.crt \\
  --key-file=/etc/etcd/${HOST}-etcd.key \\
  --peer-client-cert-auth \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-cert-file=/etc/etcd/${HOST}-etcd.crt \\
  --peer-key-file=/etc/etcd/${HOST}-etcd.key
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  # Create data directory
  ssh root@${HOST} mkdir -p /var/lib/etcd

done < machines.txt
```

Start the etcd service on all nodes:

```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} systemctl daemon-reload
  ssh root@${host} systemctl enable etcd
  ssh root@${host} systemctl start etcd
done
```

## Verify the etcd Cluster

Check the status of the etcd service on each node:

```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} systemctl status etcd --no-pager
done
```

Verify the cluster health using `etcdctl`. We need to provide the CA certificate and a client certificate (we can reuse one of the node certs for simplicity here, though a dedicated client cert is better practice).

```bash
NODE0_IP=$(grep node-0 machines.txt | cut -d' ' -f1)
NODE1_IP=$(grep node-1 machines.txt | cut -d' ' -f1)
NODE2_IP=$(grep node-2 machines.txt | cut -d' ' -f1)
ENDPOINTS="https://${NODE0_IP}:2379,https://${NODE1_IP}:2379,https://${NODE2_IP}:2379"

etcdctl endpoint health \
  --endpoints=${ENDPOINTS} \
  --cacert=ca.crt \
  --cert=node-0-etcd.crt \
  --key=node-0-etcd.key
```

You should see output indicating that all endpoints are healthy.

```text
https://XXX.XXX.XXX.XXX:2379 is healthy: successfully committed proposal: took = ...
https://YYY.YYY.YYY.YYY:2379 is healthy: successfully committed proposal: took = ...
https://ZZZ.ZZZ.ZZZ.ZZZ:2379 is healthy: successfully committed proposal: took = ...
```

List the members of the cluster:

```bash
etcdctl member list \
  --endpoints=${ENDPOINTS} \
  --cacert=ca.crt \
  --cert=node-0-etcd.crt \
  --key=node-0-etcd.key \
  --write-out=table
```

You should see all three nodes listed as members.

```text
+------------------+---------+--------+---------------------------+---------------------------+------------+
|        ID        | STATUS  |  NAME  |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
+------------------+---------+--------+---------------------------+---------------------------+------------+
| ...              | started | node-0 | https://XXX.XXX.XXX.XXX:2380 | https://XXX.XXX.XXX.XXX:2379 |      false |
| ...              | started | node-1 | https://YYY.YYY.YYY.YYY:2380 | https://YYY.YYY.YYY.YYY:2379 |      false |
| ...              | started | node-2 | https://ZZZ.ZZZ.ZZZ.ZZZ:2380 | https://ZZZ.ZZZ.ZZZ.ZZZ:2379 |      false |
+------------------+---------+--------+---------------------------+---------------------------+------------+
```

At this point, you have a functioning, secure 3-node etcd cluster ready for Patroni.

Next: [Installing and Configuring PostgreSQL](05-configuring-postgresql.md)
