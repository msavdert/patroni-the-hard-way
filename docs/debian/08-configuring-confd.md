# Configuring Confd

Confd is a lightweight configuration management tool that keeps local application configuration files in sync with data stored in a backend service like etcd or Consul. In this setup, confd is used to dynamically generate the HAProxy configuration file based on the Patroni cluster state information stored in the Distributed Configuration Store (DCS).

This ensures that HAProxy always routes connections to the current PostgreSQL primary node and that the list of standby nodes is kept up-to-date for read-only load balancing.