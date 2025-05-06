# Configuring Keepalived

Keepalived provides high availability by assigning a virtual IP address (VIP) to a group of servers. This VIP acts as a single entry point for database access. Keepalived uses the Virtual Router Redundancy Protocol (VRRP) for Linux. In this Patroni setup, Keepalived monitors the health of the HAProxy service. If the HAProxy service on the server holding the VIP fails, Keepalived automatically delegates the VIP to another healthy server in the cluster, ensuring continuous database accessibility.

## Installation

1.  **Install Keepalived:**
    ```bash
    sudo apt update
    sudo apt install -y keepalived
    ```

2.  **Enable the Keepalived service:**
    ```bash
    sudo systemctl enable keepalived
    sudo systemctl start keepalived
    ```

## Configuration
// ... more configuration details will be added in subsequent steps ...