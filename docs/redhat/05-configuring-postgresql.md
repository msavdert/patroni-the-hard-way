# Configuring PostgreSQL

In this section, you will install PostgreSQL 17 and the contrib package on all database nodes (`db1`, `db2`, `db3`) in your Patroni cluster. This process uses the official PostgreSQL repository and ensures the service is not started and no database is initialized at this stage, in line with the rest of the documentation.

## 1. Add the PostgreSQL Repository and Install Packages

Run the following commands from the `jumpbox` to install PostgreSQL 17 and contrib on all database nodes:

```bash
for host in db1 db2 db3; do
  ssh -n root@${host} "dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-aarch64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf -qy module disable postgresql && \
    dnf install -y postgresql17-server postgresql17-contrib"
done
```

- This will install PostgreSQL 17 and contrib, but will not start the PostgreSQL service or initialize any databases.

## 2. Verification

You can verify the installation (without starting the service) by checking the package status on each node:

```bash
for host in db1 db2 db3; do
  ssh root@${host} "rpm -qa | grep postgresql17"
done
```

You should see `postgresql17-server` and `postgresql17-contrib` listed for each host.

## 3. Next Steps

After installing PostgreSQL 17 and contrib on all database nodes, continue with Patroni configuration and cluster initialization as described in the following sections.

Next: [Configuring Patroni](06-configuring-patroni.md)
