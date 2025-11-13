# Fix for "File Version Reset" Popup Issue

This document explains the fixes implemented to resolve the persistent version reset popup issue in your OnlyOffice DocumentServer development setup.

## Problem Summary

The "file version reset, need to reload" popup was caused by:
1. **Files being copied on every container restart** - This reset file timestamps
2. **Version numbers not being tracked** - Each startup had inconsistent version info
3. **Source code volume mounts overriding built files** - Caused version mismatches

## Solution Implemented

We've implemented **Option 1: Proper Development Setup** with the following changes:

### 1. Build Script with Version Tracking (`build-with-version.sh`)
- Generates unique version numbers during build: `dev-<timestamp>.1`
- Updates `server/Common/sources/commondefines.js` with the version
- Builds all server components (Common, DocService, FileConverter, etc.)

### 2. Modified Dockerfile (`Dockerfile.dev`)
- Now **builds and copies files during image build** (not at runtime)
- Source code is baked into the image with consistent timestamps
- All builds happen once during `docker-compose build`

### 3. Updated Entrypoint (`docker/entrypoint.sh`)
- **Only copies files on first run** - checks for `.initialized` marker
- Subsequent restarts skip the copying process
- Preserves file timestamps and version consistency

### 4. Simplified docker-compose.yml
- **Removed source code volume mounts** - prevents overriding built files
- Kept only persistent data volumes (logs, data, lib)
- Source code is now in the image, not mounted

## How to Use the Fixed Setup

### Initial Build and Start

```bash
# Stop existing containers and clean volumes (IMPORTANT!)
docker-compose down -v

# Build the image (this will take several minutes)
docker-compose build --no-cache documentserver

# Start the services
docker-compose up -d

# Check logs to verify startup
docker-compose logs -f documentserver
```

### Making Code Changes

When you need to edit source code:

```bash
# 1. Make your changes to source files (server/, web-apps/, sdkjs/)

# 2. Rebuild the image
docker-compose build --no-cache documentserver

# 3. Restart the container
docker-compose up -d

# 4. Check that changes are applied
docker-compose logs -f documentserver
```

### Quick Development (Hot-Reload) - USE WITH CAUTION

If you need rapid iteration and can accept occasional version warnings:

```bash
# Use the dev hot-reload compose file
docker-compose -f docker-compose.yml -f docker-compose.dev-hotreload.yml up -d

# Make your changes to source files

# Restart to pick up changes
docker-compose restart documentserver

# IMPORTANT: When done, rebuild the image to persist changes
docker-compose build --no-cache documentserver
docker-compose -f docker-compose.yml up -d
```

**⚠️ WARNING**: Hot-reload mode can cause version mismatches. Use only for quick tests.

### Force Reinitialization

If you need to force the entrypoint to recopy files:

```bash
# Remove the initialization marker
docker-compose exec documentserver rm /var/www/onlyoffice/documentserver/.initialized

# Restart the container
docker-compose restart documentserver
```

Or completely reset:

```bash
docker-compose down -v
docker-compose up -d
```

## File Structure Changes

### Before (Hybrid Setup with Issues)
```
Container Start → Copy ALL files from mounted volumes → Reset timestamps → Version mismatch
```

### After (Fixed Setup)
```
Docker Build → Build source code → Bake into image with versions
Container Start → Copy files ONCE → Mark as initialized → Never copy again
```

## Key Benefits

✅ **No more version reset popups** - Files are only copied once
✅ **Consistent version numbers** - Tracked during build, not runtime  
✅ **Stable file timestamps** - No resets on container restart
✅ **Proper separation** - Source code in image, data in volumes
✅ **Faster restarts** - No file copying after first run

## Troubleshooting

### Problem: Still seeing version reset popup

**Solution:**
```bash
# Ensure you've removed old volumes
docker-compose down -v

# Rebuild with no cache
docker-compose build --no-cache documentserver

# Start fresh
docker-compose up -d
```

### Problem: Changes not appearing after rebuild

**Solution:**
```bash
# Make sure you're not using hot-reload mode
# Use only docker-compose.yml without the dev override

docker-compose -f docker-compose.yml build --no-cache documentserver
docker-compose -f docker-compose.yml up -d
```

### Problem: Build fails during npm install

**Solution:**
```bash
# The build script handles missing dependencies
# But if it fails, check the build logs:
docker-compose build documentserver 2>&1 | tee build.log

# Common issues:
# - Network problems: Retry the build
# - Missing system dependencies: Check Dockerfile.dev
```

### Problem: Services won't start after changes

**Solution:**
```bash
# Check if initialization is stuck
docker-compose logs documentserver

# Force reinitialization
docker-compose exec documentserver rm /var/www/onlyoffice/documentserver/.initialized
docker-compose restart documentserver

# Or start fresh
docker-compose down -v
docker-compose up -d
```

## Development Workflow

### Recommended Workflow (Stable)

1. Make code changes on your Mac
2. Build new image: `docker-compose build --no-cache documentserver`
3. Restart: `docker-compose up -d`
4. Test your changes
5. Repeat

**Build time**: ~5-10 minutes (first build may take longer)

### Alternative Workflow (Fast but Less Stable)

1. Start with hot-reload: `docker-compose -f docker-compose.yml -f docker-compose.dev-hotreload.yml up -d`
2. Make rapid changes and test
3. When satisfied, persist: `docker-compose build --no-cache documentserver`
4. Switch back: `docker-compose -f docker-compose.yml up -d`

## Files Modified

- ✅ `build-with-version.sh` - NEW: Build script with version tracking
- ✅ `Dockerfile.dev` - Modified: Build files during image creation
- ✅ `docker/entrypoint.sh` - Modified: Only copy files once
- ✅ `docker-compose.yml` - Modified: Removed source volume mounts
- ✅ `docker-compose.dev-hotreload.yml` - NEW: Optional hot-reload mode

## Comparison with Official OnlyOffice Setup

| Aspect | Official Setup | Your Fixed Setup |
|--------|---------------|------------------|
| **Installation** | Via apt packages | Built from source in Docker |
| **Version Tracking** | Package version | Build timestamp version |
| **File Persistence** | System packages | Docker image layers |
| **Code Changes** | Requires rebuild | Requires rebuild |
| **Version Consistency** | ✅ Always consistent | ✅ Now consistent |

## Next Steps

1. ✅ Stop current containers: `docker-compose down -v`
2. ✅ Build new image: `docker-compose build --no-cache documentserver`
3. ✅ Start services: `docker-compose up -d`
4. ✅ Verify no version popup appears when opening files
5. ✅ Test your workflow with a code change

## Support

If you continue to experience issues:
1. Check Docker logs: `docker-compose logs documentserver`
2. Verify build completed: Look for "✓ Build completed successfully!" in build logs
3. Check initialization: `docker-compose exec documentserver ls -la /var/www/onlyoffice/documentserver/.initialized`

---

**Date Fixed**: 2025-11-13  
**Fix Type**: Proper Development Setup (Option 1)  
**Status**: Ready for testing
