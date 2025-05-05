# Prerequisites

In this lab you will review the machine requirements necessary to follow this tutorial.

## Virtual or Physical Machines

This tutorial requires at least six (6) virtual/physical machines running **Ubuntu 24.04** or a similar Linux distribution. The following table lists the recommended minimum setup:

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
PRETTY_NAME="Ubuntu 24.04 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04 (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
```

Next: [Setting up the Jumpbox](02-jumpbox.md)
