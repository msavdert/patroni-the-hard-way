# Configuring Keepalived

Keepalived provides a virtual high-available IP address (VIP) and single entry point for databases access. It implements VRRP (Virtual Router Redundancy Protocol) for Linux. In our configuration keepalived checks the status of the HAProxy service and in case of a failure delegates the VIP to another server in the cluster.