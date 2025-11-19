#!/bin/bash

## TODOS
# 1. Check that tailscale is running via systemd service.
# 2. Run docker-compose up -d.
# 3. Run some integrity health checks against portainer.
#

## Check tailscale service daemon
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
##

## Start docker services
echo "Starting services with docker compose"

if ! docker compose up -d; then
	echo "Error: failed to start all required docker services. Please check the error messages above."
else 
	echo "All services are active and ready to accept connections."
fi
##

