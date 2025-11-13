#!/bin/bash
# Stop OnlyOffice DocumentServer services

echo "Stopping OnlyOffice DocumentServer services..."

# Stop supervisor and all services
sudo supervisorctl stop all 2>/dev/null || true
sudo pkill -f supervisord 2>/dev/null || true

# Stop Docker services
cd .devcontainer && docker-compose stop 2>/dev/null || true && cd ..

echo "✓ All services stopped"
