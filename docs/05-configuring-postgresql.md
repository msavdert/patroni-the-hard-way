# Installing and Configuring PostgreSQL

In this lab, you will install PostgreSQL server packages on each cluster node (`node-0`, `node-1`, `node-2`). Patroni will manage the PostgreSQL instances, including initialization, configuration, and starting/stopping the service. Therefore, we only need to install the necessary packages and ensure the standard PostgreSQL service is not running.

Commands in this section should be run from the `jumpbox`.

## Install PostgreSQL Packages

Install the PostgreSQL server and client packages on all three nodes. Adjust the version (e.g., `postgresql-16`) as needed for your desired PostgreSQL version.

```bash
PG_VERSION=16 # Specify desired PostgreSQL major version
for host in node-0 node-1 node-2; do
  ssh root@${host} apt-get update
  ssh root@${host} apt-get install -y postgresql-${PG_VERSION} postgresql-client-${PG_VERSION}
done
```

## Stop and Disable the Default PostgreSQL Service

Patroni needs to control the PostgreSQL process. Stop and disable the default `postgresql` service that might have been automatically started and enabled upon installation.

```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} systemctl stop postgresql
  ssh root@${host} systemctl disable postgresql
done
```

Verify the service is stopped and disabled:

```bash
for host in node-0 node-1 node-2; do
  ssh root@${host} systemctl is-active postgresql
  ssh root@${host} systemctl is-enabled postgresql
done
```

You should see `inactive` and `disabled` for each node.

## Prepare Data Directory (Optional but Recommended)

Patroni will initialize the PostgreSQL data directory if it doesn't exist. However, you might want to create a dedicated mount point or directory structure beforehand. Patroni's configuration will specify the `data_dir` location (e.g., `/var/lib/postgresql/${PG_VERSION}/main`). Ensure the parent directory exists and has appropriate permissions if you choose a non-default location. For this tutorial, we will rely on Patroni using the default location, which should already exist after package installation.

At this point, PostgreSQL packages are installed on all nodes, and the default service is stopped, ready for Patroni to take over management.

Next: [Installing and Configuring Patroni](06-configuring-patroni.md)
