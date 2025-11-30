#!/bin/bash

# --- Stop docker processes ---
echo "Shutting down docker services..."
docker compose -f ../docker-compose.yml down
echo "Docker services have been stopped. Shutting down homelab..."
# ---
