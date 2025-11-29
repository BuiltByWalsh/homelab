#!/bin/bash

set -e

# --- 1. Read the .env directory one directory up to pull in env vars. ---
PROJECT_ROOT="$(dirname "$(dirname "$PWD")")"
ENV_FILE="$PROJECT_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
    echo "Loading environment variables from $ENV_FILE"
    # Use 'set -a' to export all variables read from the file
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "Error: .env file not found"
    exit 1
fi
# ---

# --- 2. Check if SERVICE_INSTALL_PATH was successfully loaded from the .env file ---
if [[ -z "$SERVICE_INSTALL_PATH" ]]; then
    echo "Error: SERVICE_INSTALL_PATH is not set in the .env file."
    exit 1
fi

echo "Service install path set to: $SERVICE_INSTALL_PATH"
# ---

# --- 3. Symlink homelab.service into the SERVICE_INSTALL_PATH env var value ---

echo "Creating homelab.service symlink in $SERVICE_INSTALL_PATH..."

sudo ln -sf lib/homelab.service "$SERVICE_INSTALL_PATH/homelab.service"

echo "Installation script finished. Service symlink created successfully."
# ---

# --- 4 Optional: Provide final instructions to stdout ---
echo ""
echo "To enable and start the homelab service:"
echo "sudo systemctl daemon-reload"
echo "sudo systemctl enable homelab.service"
echo "sudo systemctl start homelab.service"
# ---
