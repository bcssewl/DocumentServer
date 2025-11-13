#!/bin/bash
set -e

echo "================================================"
echo "Setting up OnlyOffice Development Environment"
echo "================================================"
echo ""

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if pg_isready -h postgres -U onlyoffice > /dev/null 2>&1; then
        echo "✓ PostgreSQL is ready!"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 2
done

# Wait for RabbitMQ to be ready
echo "Waiting for RabbitMQ to be ready..."
for i in {1..30}; do
    if curl -s http://guest:guest@rabbitmq:15672/api/overview > /dev/null 2>&1; then
        echo "✓ RabbitMQ is ready!"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 2
done

echo ""
echo "================================================"
echo "Installing project dependencies..."
echo "================================================"
echo ""

cd /workspace

# Install server dependencies (if not already done)
if [ -d "server" ] && [ ! -d "server/node_modules" ]; then
    echo "Installing server dependencies..."
    cd server
    npm install || echo "⚠️  Some server dependencies failed (might be SpellChecker)"
    cd /workspace
fi

# Install web-apps dependencies
if [ -d "web-apps" ] && [ ! -d "web-apps/node_modules" ]; then
    echo "Installing web-apps dependencies..."
    cd web-apps
    npm install || echo "⚠️  Some web-apps dependencies failed"
    cd /workspace
fi

# Install sdkjs dependencies
if [ -d "sdkjs" ] && [ ! -d "sdkjs/node_modules" ]; then
    echo "Installing sdkjs dependencies..."
    cd sdkjs
    npm install || echo "⚠️  Some sdkjs dependencies failed"
    cd /workspace
fi

echo ""
echo "================================================"
echo "✓ Development environment setup complete!"
echo "================================================"
echo ""
echo "Quick Start Commands:"
echo "  ./build-with-version.sh       # Build all components"
echo "  ./start-services.sh            # Start DocumentServer services"
echo "  ./stop-services.sh             # Stop services"
echo ""
echo "Access DocumentServer at:"
echo "  http://localhost:9090"
echo ""
echo "Forwarded ports:"
echo "  9090  - DocumentServer HTTP"
echo "  5432  - PostgreSQL"
echo "  5672  - RabbitMQ"
echo "  15672 - RabbitMQ Management UI"
echo ""
