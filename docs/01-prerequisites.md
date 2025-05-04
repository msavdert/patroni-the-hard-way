# Prerequisites

In this lab you will review the machine requirements necessary to follow this tutorial.

## Virtual or Physical Machines

This tutorial requires at least five (5) virtual/physical machines running **Rocky Linux 9** or a similar Linux distribution. The following table lists the recommended minimum setup:

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
NAME="Rocky Linux"
VERSION="9.x (Core)"
ID="rocky"
ID_LIKE="rhel fedora"
VERSION_ID="9.x"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Rocky Linux 9.x (Core)"
```

Next: [Setting up the Jumpbox](02-jumpbox.md)
