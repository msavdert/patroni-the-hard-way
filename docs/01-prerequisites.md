# Prerequisites

In this lab you will review the machine requirements necessary to follow this tutorial.

## Virtual or Physical Machines (or Containers)

This tutorial requires at least five (5) virtual/physical machines or containers running **Rocky Linux 9** or a similar Linux distribution. The following table lists the recommended minimum setup:

| Name    | Description                                  | CPU | RAM   | Storage |
|---------|----------------------------------------------|-----|-------|---------|
| jumpbox | Administration host                          | 1   | 512MB | 10GB    |
| haproxy | Load Balancer Host                           | 1   | 512MB | 10GB    |
| node-0  | Patroni Cluster Node (etcd, PostgreSQL)      | 1   | 2GB   | 20GB    |
| node-1  | Patroni Cluster Node (etcd, PostgreSQL)      | 1   | 2GB   | 20GB    |
| node-2  | Patroni Cluster Node (etcd, PostgreSQL)      | 1   | 2GB   | 20GB    |

*Note: For simplicity, we'll co-locate etcd and PostgreSQL/Patroni on the same nodes in this guide. In production, you might separate these roles onto different machines depending on load and redundancy requirements. HAProxy could also run on the jumpbox or dedicated nodes.*

## Setup Options

### Option 1: Using Docker (Recommended)

For those who prefer a simplified setup, we provide a Docker-based environment that creates all the necessary containers in one step. This method is ideal for testing and learning.

To start all required containers:

```bash
docker-compose up -d --build
```

This command builds and starts all the necessary containers (jumpbox, haproxy, node-0, node-1, node-2) based on Rocky Linux 9 with SSH access enabled. You can connect to the containers using:

```bash
# Connect to jumpbox
docker exec -it jumpbox bash

# Or connect via SSH
ssh root@localhost -p 22222 # password: password
```

After running the containers, proceed to [Setting up the Jumpbox](02-jumpbox.md) where all subsequent commands should be executed from the jumpbox container.

### Option 2: Manual Setup with Virtual Machines

If you prefer using virtual or physical machines, you'll need to provision them manually according to the specifications above.

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
