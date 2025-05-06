# Provisioning Compute Resources

Patroni requires a set of machines to host the Distributed Configuration Store (DCS) like Consul, the PostgreSQL instances managed by Patroni, and HAProxy/PgBouncer for load balancing. In this lab you will provision the machines required for setting up a Patroni cluster.

## Machine Database

This tutorial will leverage a text file, which will serve as a machine database, to store the various machine attributes that will be used when setting up the Patroni cluster nodes. The following schema represents entries in the machine database, one entry per line:

```text
IPV4_ADDRESS FQDN HOSTNAME
```

Each of the columns corresponds to a machine IP address `IPV4_ADDRESS`, fully qualified domain name `FQDN`, and host name `HOSTNAME`.

Here is an example machine database similar to the one used when creating this tutorial. Notice the IP addresses have been masked out. Your machines can be assigned any IP address as long as each machine is reachable from each other and the `jumpbox`.

```bash
cat machines.txt
```

```text
XXX.XXX.XXX.XXX db1.patroni.local db1
XXX.XXX.XXX.XXX db2.patroni.local db2
XXX.XXX.XXX.XXX db3.patroni.local db3
XXX.XXX.XXX.XXX proxy1.patroni.local proxy1
XXX.XXX.XXX.XXX proxy2.patroni.local proxy2
```

Now it's your turn to create a `machines.txt` file with the details for the machines you will be using to create your Patroni cluster. Use the example machine database from above and add the details for your machines.

## Configuring SSH Access

SSH will be used to configure the machines in the cluster. Verify that you have `root` SSH access to each machine listed in your machine database. You may need to enable root SSH access on each node by updating the sshd_config file and restarting the SSH server.

### Enable root SSH Access

If `root` SSH access is enabled for each of your machines you can skip this section.

By default, a new `ubuntu` install disables SSH access for the `root` user. This is done for security reasons as the `root` user has total administrative control of unix-like systems. If a weak password is used on a machine connected to the internet, well, let's just say it's only a matter of time before your machine belongs to someone else. As mentioned earlier, we are going to enable `root` access over SSH in order to streamline the steps in this tutorial. Security is a tradeoff, and in this case, we are optimizing for convenience. Log on to each machine via SSH using your user account, then switch to the `root` user using the `su` command:

```bash
su - root
```

Edit the `/etc/ssh/sshd_config` SSH daemon configuration file and set the `PermitRootLogin` option to `yes`:

```bash
sed -i \
  's/^#*PermitRootLogin.*/PermitRootLogin yes/' \
  /etc/ssh/sshd_config
```

Restart the `sshd` SSH server to pick up the updated configuration file:

```bash
systemctl restart sshd
```

### Generate and Distribute SSH Keys

In this section you will generate and distribute an SSH keypair to the `db1`, `db2`, `db3`, `proxy1`, and `proxy2` machines, which will be used to run commands on those machines throughout this tutorial. Run the following commands from the `jumpbox` machine.

Generate a new SSH key:

```bash
ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -N ''
```

Copy the SSH public key to each machine:

```bash
while read IP FQDN HOST; do
  if [ "$HOST" != "vip" ]; then
    ssh-copy-id root@${IP}
  fi
done < machines.txt
```

Once each key is added, verify SSH public key access is working:

```bash
while read IP FQDN HOST; do
  if [ "$HOST" != "vip" ]; then
    ssh -n root@${IP} hostname
  fi
done < machines.txt
```

```text
db1
db2
db3
proxy1
proxy2
```

## Hostnames

In this section you will assign hostnames to the `db1`, `db2`, `db3`, `proxy1`, and `proxy2` machines. The hostname will be used when executing commands from the `jumpbox` to each machine. The hostname also plays a role within the cluster, particularly for node identification in the DCS and for inter-node communication.

To configure the hostname for each machine, run the following commands on the `jumpbox`.

Set the hostname on each machine listed in the `machines.txt` file:

```bash
while read IP FQDN HOST SUBNET; do
    CMD="sed -i 's/^127.0.1.1.*/127.0.1.1\t${FQDN} ${HOST}/' /etc/hosts"
    ssh -n root@${IP} "$CMD"
    ssh -n root@${IP} hostnamectl set-hostname ${HOST}
    ssh -n root@${IP} systemctl restart systemd-hostnamed
done < machines.txt
```

Verify the hostname is set on each machine:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n root@${IP} hostname --fqdn
done < machines.txt
```

```text
db1.patroni.local
db2.patroni.local
db3.patroni.local
proxy1.patroni.local
proxy2.patroni.local
```

## Host Lookup Table

In this section you will generate a `hosts` file which will be appended to `/etc/hosts` file on the `jumpbox` and to the `/etc/hosts` files on all cluster members used for this tutorial. This will allow each machine to be reachable using a hostname such as `db1`, `db2`, `db3`, `proxy1`, or `proxy2`.

Create a new `hosts` file and add a header to identify the machines being added:

```bash
echo "" > hosts
echo "# Patroni The Hard Way" >> hosts
```

Generate a host entry for each machine in the `machines.txt` file and append it to the `hosts` file:

```bash
while read IP FQDN HOST; do
    ENTRY="${IP} ${FQDN} ${HOST}"
    echo $ENTRY >> hosts
done < machines.txt
```

Review the host entries in the `hosts` file:

```bash
cat hosts
```

```text

# Patroni The Hard Way
XXX.XXX.XXX.XXX db1.patroni.local db1
XXX.XXX.XXX.XXX db2.patroni.local db2
XXX.XXX.XXX.XXX db3.patroni.local db3
XXX.XXX.XXX.XXX proxy1.patroni.local proxy1
XXX.XXX.XXX.XXX proxy2.patroni.local proxy2
```

## Adding `/etc/hosts` Entries To A Local Machine

In this section you will append the DNS entries from the `hosts` file to the local `/etc/hosts` file on your `jumpbox` machine.

Append the DNS entries from `hosts` to `/etc/hosts`:

```bash
cat hosts >> /etc/hosts
```

Verify that the `/etc/hosts` file has been updated:

```bash
cat /etc/hosts
```

```text
127.0.0.1       localhost
127.0.1.1       jumpbox

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# Patroni The Hard Way
XXX.XXX.XXX.XXX jumpbox.patroni.local jumpbox
XXX.XXX.XXX.XXX db1.patroni.local db1
XXX.XXX.XXX.XXX db2.patroni.local db2
XXX.XXX.XXX.XXX db3.patroni.local db3
XXX.XXX.XXX.XXX proxy1.patroni.local proxy1
XXX.XXX.XXX.XXX proxy2.patroni.local proxy2
XXX.XXX.XXX.XXX vip.patroni.local vip
```

At this point you should be able to SSH to each machine listed in the `machines.txt` file using a hostname.

```bash
for host in db1 db2 db3 proxy1 proxy2
   do ssh root@${host} hostname
done
```

```text
db1
db2
db3
proxy1
proxy2
```

## Adding `/etc/hosts` Entries To The Remote Machines

In this section you will append the host entries from `hosts` to `/etc/hosts` on each machine listed in the `machines.txt` text file.

Copy the `hosts` file to each machine and append the contents to `/etc/hosts`:

```bash
while read IP FQDN HOST SUBNET; do
  scp hosts root@${HOST}:~/
  ssh -n \
    root@${HOST} "cat hosts >> /etc/hosts"
done < machines.txt
```

At this point, hostnames can be used when connecting to machines from your `jumpbox` machine, or any of the machines in the Patroni cluster. Instead of using IP addresses you can now connect to machines using a hostname such as `db1`, `db2`, `db3`, `proxy1`, or `proxy2`.

## Ensuring Time Synchronization with chrony

Accurate time synchronization is critical for distributed systems. In this section, you will install and start the chrony service on all database and proxy nodes to ensure system clocks remain in sync.

Run the following commands from the `jumpbox` to install, enable, and start chrony on all db1, db2, db3, proxy1, and proxy2 nodes:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n \
    root@${HOST} "apt-get update && apt-get install -y chrony && systemctl enable chrony && systemctl start chrony"
done < machines.txt
```

Verify that chrony is running on all nodes:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n \
    root@${HOST} "systemctl status chrony --no-pager | grep Active"
    echo "Checked chrony on $host"
done < machines.txt
```

### Disable and Stop Firewall Services

To avoid connectivity issues during the tutorial, disable and stop any firewall services on the jumpbox:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n \
    root@${HOST} "systemctl disable --now ufw || true"
done < machines.txt
```

### Install and Enable Time Synchronization (chrony)

Accurate time synchronization is critical for distributed systems. Install, enable, and start the chrony service:

```bash
apt install -y chrony
systemctl enable chrony
systemctl start chrony
```

Next: [Setting up the Distributed Configuration Store (etcd)](04-setting-up-dcs.md)
