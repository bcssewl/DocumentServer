# ONLYOFFICE DocumentServer - Development with Docker

This guide explains how to build and run ONLYOFFICE DocumentServer from source using Docker on your MacBook.

## Prerequisites

- Docker Desktop for Mac
- Docker Compose
- At least 8GB RAM allocated to Docker
- 40GB free disk space

## Quick Start

### 1. Build and Run

```bash
# Build the Docker image and start all services
docker-compose up --build
```

This will:
- Build the DocumentServer from source
- Start PostgreSQL database
- Start RabbitMQ message broker
- Start all DocumentServer services
- Expose the application on http://localhost:8080

### 2. Access the Application

Once all services are running, access DocumentServer at:
- **DocumentServer**: http://localhost:8080
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

## Development Workflow

### Editing Code

The source code is mounted as volumes in the container, so you can edit files directly on your Mac:

- `./core` - C++ core components
- `./server` - Node.js backend services
- `./web-apps` - Frontend web applications
- `./sdkjs` - JavaScript SDK

### Rebuilding After Changes

#### Rebuild JavaScript Components (sdkjs, web-apps, server)

```bash
# Rebuild sdkjs
docker-compose exec documentserver sh -c "cd /app/DocumentServer/sdkjs && make"

# Rebuild web-apps
docker-compose exec documentserver sh -c "cd /app/DocumentServer/web-apps && make"

# Rebuild server
docker-compose exec documentserver sh -c "cd /app/DocumentServer/server && make"

# Restart services
docker-compose restart documentserver
```

#### Rebuild C++ Core Components

For core C++ changes, you'll need to rebuild using build_tools:

```bash
# Enter the container
docker-compose exec documentserver bash

# Navigate to build_tools
cd /build_tools/tools/linux

# Rebuild
python3 automate.py server

# Exit and restart
exit
docker-compose restart documentserver
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f documentserver

# Inside container logs
docker-compose exec documentserver tail -f /var/log/onlyoffice/documentserver/docservice.log
```

## Useful Commands

### Stop Services

```bash
docker-compose down
```

### Stop and Remove Volumes (Clean Start)

```bash
docker-compose down -v
```

### Shell Access

```bash
docker-compose exec documentserver bash
```

### Check Service Status

```bash
docker-compose exec documentserver supervisorctl status
```

### Restart Individual Services

```bash
docker-compose exec documentserver supervisorctl restart docservice
docker-compose exec documentserver supervisorctl restart converter
docker-compose exec documentserver supervisorctl restart spellchecker
```

## Architecture

### Components

1. **DocService** (port 8000) - Main document service
2. **FileConverter** - Converts documents between formats
3. **SpellChecker** - Spell checking service
4. **Metrics** - Monitoring and metrics
5. **NGINX** (port 80) - Reverse proxy

### Database

- **PostgreSQL** (port 5432)
  - Database: onlyoffice
  - User: onlyoffice
  - Password: onlyoffice

### Message Queue

- **RabbitMQ** (ports 5672, 15672)
  - User: guest
  - Password: guest

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker-compose logs documentserver
```

### Out of Memory

Increase Docker memory allocation in Docker Desktop preferences to at least 8GB.

### Port Already in Use

Change ports in `docker-compose.yml`:
```yaml
ports:
  - "9090:80"  # Change 8080 to 9090 or any available port
```

### Build Fails

Clean build and retry:
```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

### Can't Connect to PostgreSQL

Wait for PostgreSQL to fully start (check logs):
```bash
docker-compose logs postgres
```

## Performance Notes

- First build will take 30-60 minutes depending on your Mac's specs
- Subsequent builds will be faster (5-10 minutes)
- Use `docker-compose up -d` to run in detached mode
- The source code volumes allow instant code changes without rebuild (for interpreted languages like JavaScript)

## Testing Your Changes

After making code changes:

1. **For JavaScript/Node.js changes** (server, web-apps, sdkjs):
   - Run the appropriate `make` command
   - Restart the service with supervisorctl

2. **For C++ changes** (core):
   - Rebuild with build_tools
   - Full container restart required

3. **Test your changes** at http://localhost:8080

## Production Build

For a production-ready build without development features:

```bash
docker build -f Dockerfile -t onlyoffice-documentserver-custom .
docker run -p 8080:80 onlyoffice-documentserver-custom
```

## Additional Resources

- [ONLYOFFICE API Documentation](https://api.onlyoffice.com/)
- [Official Build Instructions](https://helpcenter.onlyoffice.com/docs/installation/docs-community-compile.aspx)
- [GitHub Repository](https://github.com/ONLYOFFICE/DocumentServer)
