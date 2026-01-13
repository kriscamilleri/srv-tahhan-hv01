#!/bin/bash

# Load environment variables
source .env

DOMAIN="abc.tahhan.xyz"
EMAIL="kris@tahhan.xyz" # Change this if needed
REMOTE_DIR="/root/frigate"

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Deploying Frigate Reverse Proxy Setup to LXC $LXC_ID on $SERVER...${NC}"

# 1. Check Cloudflare Token
if grep -q "YOUR_CLOUDFLARE_API_TOKEN" backups/frigate/cloudflare.ini; then
    echo "Error: Please update backups/frigate/cloudflare.ini with your actual API token."
    exit 1
fi

# 2. Transfer Files
echo "Transferring configuration files..."
FILES="docker-compose.yml nginx.conf cloudflare.ini"

for file in $FILES; do
    echo "  - Uploading $file..."
    cat "backups/frigate/$file" | sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" \
    "pct exec $LXC_ID -- sh -c 'cat > $REMOTE_DIR/$file'"
done

# 3. Create necessary directories inside LXC
echo "Creating directories..."
sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" \
    "pct exec $LXC_ID -- mkdir -p $REMOTE_DIR/certbot/conf $REMOTE_DIR/certbot/www"

# 4. Pull new images
echo "Pulling Docker images..."
sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" \
    "pct exec $LXC_ID -- sh -c 'cd $REMOTE_DIR && docker compose pull'"

# 5. Check for existing certificates
echo "Checking for existing SSL certificates..."
CERT_EXISTS=$(sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" \
    "pct exec $LXC_ID -- sh -c 'test -d $REMOTE_DIR/certbot/conf/live/$DOMAIN && echo yes || echo no'")

if [ "$CERT_EXISTS" == "no" ]; then
    echo "No certificates found. Generating initial SSL certificate via Cloudflare..."
    # Stop nginx if running to avoid bind conflicts (though dns-01 doesn't bind port 80, keeping it clean is good)
    sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" \
        "pct exec $LXC_ID -- sh -c 'cd $REMOTE_DIR && docker compose stop nginx'"

    sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" \
        "pct exec $LXC_ID -- sh -c 'cd $REMOTE_DIR && docker compose run --rm --entrypoint \"certbot\" certbot certonly --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini --dns-cloudflare-propagation-seconds 20 --email $EMAIL --agree-tos --no-eff-email -d $DOMAIN'"
else
    echo "Certificates already exist. Skipping generation."
fi

# 6. Restart/Update Services
echo "Restarting services..."
sshpass -p "$SSH_PW" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" \
    "pct exec $LXC_ID -- sh -c 'cd $REMOTE_DIR && docker compose up -d'"

echo -e "${GREEN}Deployment Complete!${NC}"
echo "Frigate should be accessible at:"
echo "  - Public (Tailscale): https://$DOMAIN"
echo "  - Local: https://192.168.0.51:8971 (Direct)"
