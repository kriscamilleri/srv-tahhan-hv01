#!/bin/bash

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Error: .env file not found at $SCRIPT_DIR/.env"
    exit 1
fi

# Required environment variables:
# SERVER - Proxmox Host IP
# SSH_PW - Proxmox SSH Password
# LXC_ID - Frigate LXC Container ID
# CAMERA_USER - Camera Admin Username
# CAMERA_PW - Camera Admin Password

# Validate required variables
for var in SERVER SSH_PW LXC_ID CAMERA_USER CAMERA_PW; do
    if [ -z "${!var}" ]; then
        echo "Error: Environment variable $var is not set in .env"
        exit 1
    fi
done

# Camera IPs
CAMERAS=(
    "192.168.254.2"
    "192.168.254.3"
    "192.168.254.4"
    "192.168.254.5"
    "192.168.254.6"
    "192.168.254.14"
)

CURRENT_TIME=$(date +"%Y-%m-%dT%H:%M:%S")

echo "Starting camera time synchronization to: $CURRENT_TIME"

for IP in "${CAMERAS[@]}"; do
    echo "--- Syncing $IP ---"
    
    # Determine the correct XML namespace based on the device IP (Doorbell vs Turrets)
    if [[ "$IP" == "192.168.254.14" ]]; then
        XML_NS="http://www.isapi.org/ver20/XMLSchema"
    else
        XML_NS="http://www.hikvision.com/ver20/XMLSchema"
    fi

    # Create the XML payload
    XML_PAYLOAD="<?xml version='1.0' encoding='UTF-8'?><Time version='2.0' xmlns='$XML_NS'><timeMode>manual</timeMode><localTime>$CURRENT_TIME</localTime><timeZone>CST-1:00:00</timeZone></Time>"

    # Execute via Proxmox LXC
    sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "root@$SERVER" \
        "pct exec $LXC_ID -- curl -s --digest -u '$CAMERA_USER:$CAMERA_PW' -X PUT -H 'Content-Type: application/xml' -d \"$XML_PAYLOAD\" http://$IP/ISAPI/System/time" | grep -E "statusString|status|subStatusCode"
done

echo "Sync completed."
