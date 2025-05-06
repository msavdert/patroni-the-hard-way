# Configuring PgBouncer

PgBouncer is a lightweight connection pooler for PostgreSQL. It helps manage a large number of client connections to a smaller number of actual PostgreSQL server connections, reducing resource consumption and improving performance, especially for applications that open and close connections frequently.

In this Patroni setup, PgBouncer can be configured to sit between the applications and HAProxy/PostgreSQL to further optimize database connections.

## Installation

1.  **Install PgBouncer:**
    ```bash
    sudo apt update
    sudo apt install -y pgbouncer
    ```

2.  **Enable the PgBouncer service:**
    ```bash
    sudo systemctl enable pgbouncer
    sudo systemctl start pgbouncer
    ```

## Configuration
// ... more configuration details will be added in subsequent steps ...