#!/bin/bash

# --- 1. Check tailscale service daemon ---
echo "Checking status of tailscaled service..."

if ! systemctl is-active --quiet tailscaled; then
  echo "tailscaled service is not active. Attempting to enable and start it..."

  if sudo systemctl enable --now tailscaled; then
    echo "Successfully enabled tailscaled service."
  else
    echo "Error: failed to enable and start tailscaled service. Please check the error message above."
    exit 1
  fi
else
  echo "The tailscaled service is already active. No action needed."
fi
# ---

# --- 2. Start docker services ---
echo "Starting services with docker compose"

if ! docker compose -f ../docker-compose.yml up -d; then
  echo "Error: failed to start all required docker services. Please check the error messages above."
else
  echo "All services are active and ready to accept connections."
fi
# ---
