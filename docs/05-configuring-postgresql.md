# Configuring PostgreSQL

In this section, you will install PostgreSQL 17 and the contrib package on all database nodes (`db1`, `db2`, `db3`) in your Patroni cluster. This process uses the official PostgreSQL repository and ensures the service is not started and no database is initialized at this stage, in line with the rest of the documentation.

## 1. Add the PostgreSQL Repository and Install Packages

Run the following commands from the `jumpbox` to install PostgreSQL 17 and contrib on all database nodes:

```bash
for host in db1 db2 db3; do
  ssh root@${host} "
    apt install -y postgresql-common && \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh && \
    apt install -y postgresql-17 postgresql-contrib && \
    systemctl stop postgresql && \
    systemctl disable postgresql && \
    rm -rf /var/lib/postgresql/17/main/
  "
done
```

- This will install PostgreSQL 17 and contrib, but will not start the PostgreSQL service or initialize any databases.

## 2. Verification

You can verify the installation (without starting the service) by checking the package status on each node:

```bash
for host in db1 db2 db3; do
  ssh root@${host} "dpkg -l | grep postgresql-17"
done
```

You should see `postgresql-17` listed for each host.

## 3. Next Steps

After installing PostgreSQL 17 and contrib on all database nodes, continue with Patroni configuration and cluster initialization as described in the following sections.

Next: [Configuring Patroni](06-configuring-patroni.md)
