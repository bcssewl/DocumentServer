#!/bin/bash
set -e

echo "Starting ONLYOFFICE DocumentServer (Hybrid Build)..."

# Wait for PostgreSQL to be ready
until PGPASSWORD=$DB_PWD psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready!"

# Setup document root directory
DOCUMENT_ROOT="/var/www/onlyoffice/documentserver"
echo "Setting up document root at $DOCUMENT_ROOT..."

# Check if this is the first run (no existing installation)
if [ ! -f "$DOCUMENT_ROOT/.initialized" ]; then
    echo "First run detected - copying application files..."
    
    # Clean and create fresh directory structure
    rm -rf $DOCUMENT_ROOT
    mkdir -p $DOCUMENT_ROOT

    # Copy built server components (YOUR editable Node.js code)
    echo "Copying server components..."
    mkdir -p $DOCUMENT_ROOT/server
    cp -r /app/DocumentServer/server/build/server/* $DOCUMENT_ROOT/server/
else
    echo "Application already initialized - skipping file copy..."
    echo "To force reinitialization, delete $DOCUMENT_ROOT/.initialized"
fi

    # Copy server node_modules (needed at runtime)
    echo "Copying server dependencies..."
    cp -r /app/DocumentServer/server/node_modules $DOCUMENT_ROOT/server/

    # Copy node_modules for Common (shared dependencies)
    echo "Copying Common dependencies..."
    if [ -d /app/DocumentServer/server/Common/node_modules ]; then
        cp -r /app/DocumentServer/server/Common/node_modules $DOCUMENT_ROOT/server/Common/
    fi

    # Copy node_modules for each service (they have their own dependencies)
    echo "Copying service-specific dependencies..."
    if [ -d /app/DocumentServer/server/DocService/node_modules ]; then
        cp -r /app/DocumentServer/server/DocService/node_modules $DOCUMENT_ROOT/server/DocService/
    fi
    if [ -d /app/DocumentServer/server/FileConverter/node_modules ]; then
        cp -r /app/DocumentServer/server/FileConverter/node_modules $DOCUMENT_ROOT/server/FileConverter/
    fi
    if [ -d /app/DocumentServer/server/Metrics/node_modules ]; then
        cp -r /app/DocumentServer/server/Metrics/node_modules $DOCUMENT_ROOT/server/Metrics/
    fi
    if [ -d /app/DocumentServer/server/SpellChecker/node_modules ]; then
        cp -r /app/DocumentServer/server/SpellChecker/node_modules $DOCUMENT_ROOT/server/SpellChecker/
    fi

    # Copy built web-apps (YOUR editable web UI)
    echo "Copying web-apps..."
    cp -r /app/DocumentServer/web-apps/deploy/web-apps $DOCUMENT_ROOT/

    # Copy built sdkjs (YOUR editable SDK)
    echo "Copying sdkjs..."
    cp -r /app/DocumentServer/sdkjs/deploy/sdkjs $DOCUMENT_ROOT/

    # Copy generated fonts and AllFonts.js
    echo "Copying generated fonts..."
    cp -r /app/DocumentServer/fonts $DOCUMENT_ROOT/
    cp /app/DocumentServer/sdkjs/common/AllFonts.js $DOCUMENT_ROOT/sdkjs/common/

    # Copy server AllFonts.js if it exists
    if [ -f /app/DocumentServer/server/FileConverter/bin/AllFonts.js ]; then
        mkdir -p $DOCUMENT_ROOT/server/FileConverter/bin
        cp /app/DocumentServer/server/FileConverter/bin/AllFonts.js $DOCUMENT_ROOT/server/FileConverter/bin/
    fi

    # Copy generated themes and images
    echo "Copying themes and images..."
    cp -r /app/DocumentServer/sdkjs/common/Images/* $DOCUMENT_ROOT/sdkjs/common/Images/

    # Copy prebuilt C++ tools (for FileConverter if needed)
    echo "Copying C++ tools and libraries..."
    mkdir -p $DOCUMENT_ROOT/server/FileConverter/bin
    mkdir -p $DOCUMENT_ROOT/server/tools
    cp /app/DocumentServer/prebuilt-tools/allfontsgen $DOCUMENT_ROOT/server/tools/
    cp /app/DocumentServer/prebuilt-tools/allthemesgen $DOCUMENT_ROOT/server/tools/
    cp -r /app/DocumentServer/prebuilt-tools/bin/* $DOCUMENT_ROOT/server/FileConverter/bin/ 2>/dev/null || true

    # Copy core-fonts for runtime font operations
    echo "Copying core-fonts..."
    cp -r /app/DocumentServer/core-fonts $DOCUMENT_ROOT/

    # Copy dictionaries for spell checking
    if [ -d /app/DocumentServer/dictionaries ]; then
        echo "Copying dictionaries..."
        cp -r /app/DocumentServer/dictionaries $DOCUMENT_ROOT/
    fi

    # Create sdkjs-plugins directory (for custom plugins)
    echo "Creating plugins directory..."
    mkdir -p $DOCUMENT_ROOT/sdkjs-plugins

    # Set up log4js configs
    echo "Setting up logging configuration..."
    mkdir -p /etc/onlyoffice/documentserver/log4js
    if [ -d $DOCUMENT_ROOT/server/Common/config/log4js ]; then
        cp -r $DOCUMENT_ROOT/server/Common/config/log4js/* /etc/onlyoffice/documentserver/log4js/
    fi

    # Set up local.json with JWT configuration in the correct location
    echo "Setting up JWT configuration..."
    mkdir -p $DOCUMENT_ROOT/server/Common/config
    cat > $DOCUMENT_ROOT/server/Common/config/local.json <<'EOF'
{
  "services": {
    "CoAuthoring": {
      "secret": {
        "inbox": {
          "string": "local-dev-secret-change-in-production"
        },
        "outbox": {
          "string": "local-dev-secret-change-in-production"
        },
        "session": {
          "string": "local-dev-secret-change-in-production"
        }
      },
      "token": {
        "enable": {
          "request": {
            "inbox": true,
            "outbox": true
          },
          "browser": true
        }
      }
    }
  }
}
EOF
    echo "✓ JWT configuration created at $DOCUMENT_ROOT/server/Common/config/local.json"

    # Set proper permissions
    echo "Setting permissions..."
    chown -R ds:ds $DOCUMENT_ROOT 2>/dev/null || true
    chmod -R 755 $DOCUMENT_ROOT

    # Verify critical files exist
    echo "Verifying setup..."
    if [ ! -f "$DOCUMENT_ROOT/sdkjs/common/AllFonts.js" ]; then
        echo "ERROR: AllFonts.js not found!"
        exit 1
    fi

    if [ ! -d "$DOCUMENT_ROOT/web-apps/apps/documenteditor" ]; then
        echo "ERROR: Document editor not found!"
        exit 1
    fi

    if [ ! -d "$DOCUMENT_ROOT/server/DocService" ]; then
        echo "ERROR: DocService not found!"
        exit 1
    fi

    # Mark as initialized
    touch $DOCUMENT_ROOT/.initialized
    echo "✓ Created initialization marker at $DOCUMENT_ROOT/.initialized"

    echo "✓ All components assembled successfully!"
    echo "✓ Using YOUR editable code from:"
    echo "  - server/ (Node.js services)"
    echo "  - web-apps/ (Web UI)"
    echo "  - sdkjs/ (JavaScript SDK)"
    echo "✓ Using pre-built C++ tools for font/theme generation"
    echo ""
    echo "Document root: $DOCUMENT_ROOT"
fi

# Add WASM MIME type to NGINX if not already present
echo "Configuring NGINX MIME types..."
if ! grep -q "application/wasm" /etc/nginx/mime.types 2>/dev/null; then
    sed -i '/application\/octet-stream/a\    application/wasm                                       wasm;' /etc/nginx/mime.types
    echo "✓ Added WASM MIME type to NGINX"
fi

echo "Ready to start services..."

# Execute the main command
exec "$@"
