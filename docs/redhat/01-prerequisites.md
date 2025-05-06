# Prerequisites

In this lab you will review the machine requirements necessary to follow this tutorial.

## Virtual or Physical Machines

This tutorial requires at least six (6) virtual/physical machines running **Oracle Linux 9** or a similar Red Hat-based Linux distribution. The following table lists the recommended minimum setup:

| Name    | Description                                  | CPU | RAM   | Storage |
|---------|----------------------------------------------|-----|-------|---------|
| jumpbox | Administration host                          | 1   | 512MB | 10GB    |
| db1     | PostgreSQL + Patroni + Consul node           | 1   | 2GB   | 20GB    |
| db2     | PostgreSQL + Patroni + Consul node           | 1   | 2GB   | 20GB    |
| db3     | PostgreSQL + Patroni + Consul node           | 1   | 2GB   | 20GB    |
| proxy1  | HAProxy + PgBouncer + Keepalived (MASTER)    | 1   | 1GB   | 10GB    |
| proxy2  | HAProxy + PgBouncer + Keepalived (BACKUP)    | 1   | 1GB   | 10GB    |

*Note: For simplicity, we'll co-locate PostgreSQL, Patroni and Consul on the same nodes in this guide. In production, you might separate these roles onto different machines depending on load and redundancy requirements.*

How you provision the machines is up to you, the only requirement is that each machine meet the above system requirements including the machine specs and OS version. Once you have all six machines provisioned, verify the OS requirements by viewing the `/etc/os-release` file:

```bash
cat /etc/os-release
```

You should see something similar to the following output:

```text
NAME="Oracle Linux Server"
VERSION="9.5"
ID="ol"
ID_LIKE="fedora"
VARIANT="Server"
VARIANT_ID="server"
VERSION_ID="9.5"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Oracle Linux Server 9.5"
```

Next: [Setting up the Jumpbox](02-jumpbox.md)
