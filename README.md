# Patroni The Hard Way

This tutorial walks you through setting up a highly available PostgreSQL cluster using Patroni the hard way. This guide is not for someone looking for a fully automated tool to bring up a Patroni cluster. Patroni The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a resilient PostgreSQL cluster managed by Patroni.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!

## Copyright

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.


## Target Audience

The target audience for this tutorial is someone who wants to understand the fundamentals of Patroni, PostgreSQL high availability, and how the core components (PostgreSQL, Patroni, Distributed Configuration Store) fit together.

## Cluster Details

Patroni The Hard Way guides you through bootstrapping a basic highly available PostgreSQL cluster with a distributed configuration store (like etcd), Patroni managing the PostgreSQL instances, and potentially a load balancer for client connections.

Component versions:

* [Patroni](https://github.com/zalando/patroni) v4.x
* [PostgreSQL](https://www.postgresql.org/) v17.x
* [Consul](https://github.com/hashicorp/consul/) v1.20.x (or Etcd/Zookeeper)
* [HAProxy](https://github.com/haproxy/haproxy/) v3.x
* [PgBouncer](https://github.com/pgbouncer/pgbouncer) v1.24.x
* [Ubuntu](https://ubuntu.com/) v24.04

## Cluster Topology

The following table outlines the full cluster topology that will be built in this tutorial:

| Hostname | Roles | Ports |
|----------|-------|-------|
| db1 | PostgreSQL node<br>Patroni node<br>Consul server | 5432 (PostgreSQL)<br>8008 (Patroni API)<br>8500 (Consul) |
| db2 | PostgreSQL node<br>Patroni node<br>Consul server | 5432 (PostgreSQL)<br>8008 (Patroni API)<br>8500 (Consul) |
| db3 | PostgreSQL node<br>Patroni node<br>Consul server | 5432 (PostgreSQL)<br>8008 (Patroni API)<br>8500 (Consul) |
| proxy1 | HAProxy node<br>PgBouncer node<br>Keepalived MASTER<br>pgAdmin host | 5000 (HAProxy RW)<br>5001 (HAProxy RO)<br>5432 (PgBouncer)<br>80 (pgAdmin) |
| proxy2 | HAProxy node<br>PgBouncer node<br>Keepalived BACKUP | 5000 (HAProxy RW)<br>5001 (HAProxy RO)<br>5432 (PgBouncer) |
| VIP | Virtual IP – Managed by Keepalived | 5432 (PgBouncer)<br>5000 (HAProxy RW)<br>5001 (HAProxy RO) |

## Labs

This tutorial requires at least three (3) ARM64 or AMD64 based virtual or physical machines connected to the same network for a minimal HA setup (e.g., 3 etcd nodes, 3 PostgreSQL/Patroni nodes, potentially overlapping). Adjust based on your chosen DCS and redundancy goals.

* [Prerequisites](docs/01-prerequisites.md)
* [Setting up the Jumpbox](docs/02-jumpbox.md)
* [Provisioning Compute Resources](docs/03-compute-resources.md)
* [Setting up the Distributed Configuration Store (etcd)](docs/04-setting-up-dcs.md)
* [Installing and Configuring PostgreSQL](docs/05-configuring-postgresql.md)
* [Installing and Configuring Patroni](docs/06-configuring-patroni.md)
* [Bootstrapping the Patroni Cluster](docs/07-bootstrapping-patroni.md)
* [Configuring Client Access (HAProxy)](docs/08-configuring-client-access.md)
* [Testing Failover](docs/09-testing-failover.md)
* [Smoke Test](docs/10-smoke-test.md)
* [Cleaning Up](docs/11-cleanup.md)
