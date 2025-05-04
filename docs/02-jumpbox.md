# Set Up The Jumpbox

In this lab you will set up one of the machines to be a `jumpbox`. This machine will be used to run commands throughout this tutorial. While a dedicated machine is being used to ensure consistency, these commands can also be run from just about any machine including your personal workstation running macOS or Linux.

Think of the `jumpbox` as the administration machine that you will use as a home base when setting up your Patroni cluster from the ground up. Before we get started we need to install a few command line utilities and clone the Patroni The Hard Way git repository, which contains some additional configuration files that will be used throughout this tutorial.

Log in to the `jumpbox`:

```bash
ssh root@jumpbox
```

All commands will be run as the `root` user. This is being done for the sake of convenience, and will help reduce the number of commands required to set everything up.

### Install Command Line Utilities

Now that you are logged into the `jumpbox` machine as the `root` user, you will install the command line utilities that will be used to perform various tasks throughout the tutorial.

```bash
{
  dnf update -y
  dnf install -y wget curl-minimal vim openssl git
}
```

### Sync GitHub Repository

Now it's time to download a copy of this tutorial which contains the configuration files and templates that will be used build your Patroni cluster from the ground up. Clone the Patroni The Hard Way git repository using the `git` command:

```bash
git clone --depth 1 \
  https://github.com/msavdert/patroni-the-hard-way.git
```

Change into the `patroni-the-hard-way` directory:

```bash
cd patroni-the-hard-way
```

This will be the working directory for the rest of the tutorial. If you ever get lost run the `pwd` command to verify you are in the right directory when running commands on the `jumpbox`:

```bash
pwd
```

```text
/root/patroni-the-hard-way
```

At this point the `jumpbox` has been set up with the basic command line tools and utilities necessary to complete the labs in this tutorial. Specific software like Patroni, PostgreSQL, and etcd will be installed on the cluster nodes in later steps.

Next: [Provisioning Compute Resources](03-compute-resources.md)
