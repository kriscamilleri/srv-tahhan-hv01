# Configuration Backups

This directory contains backups of the configuration files for the Tahhan Server (Proxmox and Frigate).

## Architecture Overview

The surveillance system is deployed using a nested virtualization strategy for optimal performance and management:

1.  **Proxmox VE (Host)**: The base operating system managing hardware and virtual resources.
    *   **Hardware Passthrough**: The Google Coral TPU (USB) and Intel Integrated GPU (`/dev/dri/renderD128`) are passed from the host directly to the LXC container.
    *   **Storage**: A ZFS dataset located at `/zfs-hv01-slow/cctv` is bind-mounted to the LXC for high-performance video storage.

2.  **LXC Container (ID 151 - Debian)**: A lightweight Linux container that acts as the primary service environment.
    *   **Docker Engine**: Runs inside the LXC to handle container orchestration.
    *   **Privileged Mode**: The LXC runs in privileged mode to allow seamless access to the passed-through hardware devices.

3.  **Frigate (Docker Container)**: The NVR application running within the LXC.
    *   **Inference**: Uses the Google Coral TPU for real-time object detection (detecting people, cars, etc.).
    *   **FFmpeg Acceleration**: Uses Intel VAAPI (`i965` driver) for hardware-accelerated video decoding.

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
To refresh these backups, run the following commands from the project root (ensure `.env` variables are exported or substitute manually):
```bash
# Proxmox LXC Config
sshpass -p "$SSH_PW" ssh "$SSH_USER@$SERVER" "cat /etc/pve/lxc/$LXC_ID.conf" > backups/proxmox/$LXC_ID.conf

# Frigate Config
sshpass -p "$SSH_PW" ssh "$SSH_USER@$SERVER" "pct exec $LXC_ID -- cat /root/frigate/config/config.yml" > backups/frigate/config.yml

# Frigate Docker Compose
sshpass -p "$SSH_PW" ssh "$SSH_USER@$SERVER" "pct exec $LXC_ID -- cat /root/frigate/docker-compose.yml" > backups/frigate/docker-compose.yml
```
