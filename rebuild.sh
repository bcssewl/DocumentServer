#!/bin/bash

# ONLYOFFICE DocumentServer - Quick Rebuild Helper
# Use this script to rebuild and restart after making code changes

set -e

echo "========================================="
echo "ONLYOFFICE DocumentServer Rebuild"
echo "========================================="
echo ""

# Parse arguments
CLEAN=""
NO_CACHE="--no-cache"

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean|-c)
            CLEAN="yes"
            shift
            ;;
        --keep-cache)
            NO_CACHE=""
            shift
            ;;
        --help|-h)
            echo "Usage: ./rebuild.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --clean, -c        Remove all volumes and data before rebuild"
            echo "  --keep-cache       Keep Docker build cache (faster but may not pick up all changes)"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./rebuild.sh                    # Normal rebuild"
            echo "  ./rebuild.sh --clean            # Clean rebuild (removes all data)"
            echo "  ./rebuild.sh --keep-cache       # Fast rebuild (uses cache)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Step 1: Stop containers
echo "Step 1: Stopping containers..."
docker-compose stop documentserver

if [ "$CLEAN" = "yes" ]; then
    echo ""
    echo "⚠️  WARNING: --clean flag detected!"
    echo "This will remove ALL data including:"
    echo "  - Database data"
    echo "  - Logs"
    echo "  - Cache"
    echo "  - Document storage"
    echo ""
    read -p "Are you sure? (yes/NO): " -r
    echo
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Removing all containers and volumes..."
        docker-compose down -v
    else
        echo "Aborted."
        exit 1
    fi
else
    docker-compose down
fi

# Step 2: Build image
echo ""
echo "Step 2: Building Docker image..."
if [ -n "$NO_CACHE" ]; then
    echo "Building with no cache (recommended)..."
else
    echo "Building with cache (faster)..."
fi

docker-compose build $NO_CACHE documentserver

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed! Check the output above for errors."
    exit 1
fi

# Step 3: Start services
echo ""
echo "Step 3: Starting services..."
docker-compose up -d

# Step 4: Wait and check status
echo ""
echo "Step 4: Waiting for services to start..."
sleep 5

# Show status
echo ""
echo "Service status:"
docker-compose ps

# Show recent logs
echo ""
echo "Recent logs (last 20 lines):"
docker-compose logs --tail=20 documentserver

echo ""
echo "========================================="
echo "✅ Rebuild complete!"
echo "========================================="
echo ""
echo "Access DocumentServer at: http://localhost:9090"
echo ""
echo "Useful commands:"
echo "  docker-compose logs -f documentserver    # Follow logs"
echo "  docker-compose restart documentserver    # Restart service"
echo "  docker-compose exec documentserver bash  # Shell access"
echo ""
