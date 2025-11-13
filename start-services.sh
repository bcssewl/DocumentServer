#!/bin/bash
# Start OnlyOffice DocumentServer services in Codespaces

set -e

echo "================================================"
echo "Starting OnlyOffice DocumentServer Services"
echo "================================================"
echo ""

# Create necessary directories
sudo mkdir -p /var/www/onlyoffice/documentserver
sudo mkdir -p /var/log/onlyoffice/documentserver
sudo mkdir -p /var/lib/onlyoffice/documentserver/App_Data
sudo mkdir -p /etc/onlyoffice/documentserver

# Set permissions
sudo chown -R vscode:vscode /var/www/onlyoffice 2>/dev/null || true
sudo chown -R vscode:vscode /var/log/onlyoffice 2>/dev/null || true
sudo chown -R vscode:vscode /var/lib/onlyoffice 2>/dev/null || true

# Check if database services are running
if ! docker ps | grep -q postgres; then
    echo "Starting database services..."
    cd .devcontainer && docker-compose up -d postgres rabbitmq redis && cd ..
    echo "Waiting for services to be ready..."
    sleep 5
fi

# Run the entrypoint script to set up files
if [ -f "docker/entrypoint.sh" ]; then
    echo "Setting up DocumentServer files..."
    export DB_TYPE=postgres
    export DB_HOST=postgres
    export DB_PORT=5432
    export DB_NAME=onlyoffice
    export DB_USER=onlyoffice
    export DB_PWD=onlyoffice
    export AMQP_URI=amqp://guest:guest@rabbitmq
    
    bash docker/entrypoint.sh supervisord -c /dev/null &
    ENTRYPOINT_PID=$!
    sleep 3
    kill $ENTRYPOINT_PID 2>/dev/null || true
fi

# Start supervisor to manage services
echo ""
echo "Starting DocumentServer services with supervisor..."
sudo supervisord -c docker/supervisord.conf

echo ""
echo "================================================"
echo "✓ Services started!"
echo "================================================"
echo ""
echo "Check service status:"
echo "  sudo supervisorctl status"
echo ""
echo "View logs:"
echo "  sudo supervisorctl tail -f docservice"
echo "  sudo supervisorctl tail -f converter"
echo ""
echo "Access DocumentServer:"
echo "  Check PORTS tab in VSCode for the forwarded URL"
echo "  Usually: https://[codespace-name]-9090.preview.app.github.dev"
echo ""
