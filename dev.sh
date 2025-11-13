#!/bin/bash

# ONLYOFFICE DocumentServer Development Helper Script

set -e

COMPOSE="docker-compose"

show_help() {
    echo "ONLYOFFICE DocumentServer Development Helper"
    echo ""
    echo "Usage: ./dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start           - Build and start all services"
    echo "  stop            - Stop all services"
    echo "  restart         - Restart all services"
    echo "  clean           - Stop and remove all containers and volumes"
    echo "  logs            - Show logs from all services"
    echo "  shell           - Open shell in documentserver container"
    echo "  build-sdkjs     - Rebuild sdkjs"
    echo "  build-webapp    - Rebuild web-apps"
    echo "  build-server    - Rebuild server"
    echo "  build-all       - Rebuild all components"
    echo "  status          - Show service status"
    echo "  help            - Show this help message"
    echo ""
}

case "$1" in
    start)
        echo "Building and starting ONLYOFFICE DocumentServer..."
        $COMPOSE up --build -d
        echo "Services started! Access at http://localhost:8080"
        ;;

    stop)
        echo "Stopping services..."
        $COMPOSE stop
        ;;

    restart)
        echo "Restarting services..."
        $COMPOSE restart
        ;;

    clean)
        echo "Cleaning up containers and volumes..."
        $COMPOSE down -v
        echo "Cleanup complete!"
        ;;

    logs)
        $COMPOSE logs -f
        ;;

    shell)
        echo "Opening shell in documentserver container..."
        $COMPOSE exec documentserver bash
        ;;

    build-sdkjs)
        echo "Rebuilding sdkjs..."
        $COMPOSE exec documentserver sh -c "cd /app/DocumentServer/sdkjs && make"
        echo "Restarting services..."
        $COMPOSE restart documentserver
        echo "Done!"
        ;;

    build-webapp)
        echo "Rebuilding web-apps..."
        $COMPOSE exec documentserver sh -c "cd /app/DocumentServer/web-apps && make"
        echo "Restarting services..."
        $COMPOSE restart documentserver
        echo "Done!"
        ;;

    build-server)
        echo "Rebuilding server..."
        $COMPOSE exec documentserver sh -c "cd /app/DocumentServer/server && make"
        echo "Restarting services..."
        $COMPOSE restart documentserver
        echo "Done!"
        ;;

    build-all)
        echo "Rebuilding all components..."
        $COMPOSE exec documentserver sh -c "cd /app/DocumentServer/sdkjs && make"
        $COMPOSE exec documentserver sh -c "cd /app/DocumentServer/web-apps && make"
        $COMPOSE exec documentserver sh -c "cd /app/DocumentServer/server && make"
        echo "Restarting services..."
        $COMPOSE restart documentserver
        echo "All components rebuilt!"
        ;;

    status)
        echo "Service status:"
        $COMPOSE ps
        echo ""
        echo "Internal service status:"
        $COMPOSE exec documentserver supervisorctl status
        ;;

    help|*)
        show_help
        ;;
esac
