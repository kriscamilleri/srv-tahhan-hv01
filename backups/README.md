# Configuration Backups

This directory contains backups of the configuration files for the Tahhan Server (Proxmox and Frigate).

## Directory Structure

### [proxmox/](proxmox/)
Contains the Proxmox LXC container configuration.
- **Source Path on Host (192.168.0.100):** `/etc/pve/lxc/151.conf`
- **Description:** Defines resources, network, and hardware passthrough (e.g., Google Coral USB) for the Frigate LXC.

### [frigate/](frigate/)
Contains the Frigate NVR configuration and deployment files.
- **Source Paths inside LXC (151):**
  - `config.yml`: `/root/frigate/config/config.yml`
  - `docker-compose.yml`: `/root/frigate/docker-compose.yml`
- **Description:** Frigate detector settings, camera streams, and Docker container orchestration.

## Backup Instructions
To refresh these backups, run the following commands from the project root:
```bash
# Proxmox LXC Config
sshpass -p 'SSH_PW' ssh root@192.168.0.100 'cat /etc/pve/lxc/151.conf' > backups/proxmox/151.conf

# Frigate Config
sshpass -p 'SSH_PW' ssh root@192.168.0.100 'pct exec 151 -- cat /root/frigate/config/config.yml' > backups/frigate/config.yml

# Frigate Docker Compose
sshpass -p 'SSH_PW' ssh root@192.168.0.100 'pct exec 151 -- cat /root/frigate/docker-compose.yml' > backups/frigate/docker-compose.yml
```
*(Replace SSH_PW with the password from .env)*
