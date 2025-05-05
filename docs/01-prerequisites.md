# Prerequisites

In this lab you will review the machine requirements necessary to follow this tutorial.

## Virtual or Physical Machines

This tutorial requires at least five (5) virtual/physical machines running **Ubuntu 24.04** or a similar Linux distribution. The following table lists the recommended minimum setup:

| Name    | Description                                  | CPU | RAM   | Storage |
|---------|----------------------------------------------|-----|-------|---------|
| jumpbox | Administration host                          | 1   | 512MB | 10GB    |
| haproxy | Load Balancer Host                           | 1   | 512MB | 10GB    |
| node-0  | Patroni Cluster Node (etcd, PostgreSQL)      | 1   | 2GB   | 20GB    |
| node-1  | Patroni Cluster Node (etcd, PostgreSQL)      | 1   | 2GB   | 20GB    |
| node-2  | Patroni Cluster Node (etcd, PostgreSQL)      | 1   | 2GB   | 20GB    |

*Note: For simplicity, we'll co-locate etcd and PostgreSQL/Patroni on the same nodes in this guide. In production, you might separate these roles onto different machines depending on load and redundancy requirements. HAProxy could also run on the jumpbox or dedicated nodes.*

How you provision the machines is up to you, the only requirement is that each machine meet the above system requirements including the machine specs and OS version. Once you have all five machines provisioned, verify the OS requirements by viewing the `/etc/os-release` file:

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
