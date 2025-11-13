# Implementation Summary: Version Reset Fix

## Changes Made

### ✅ New Files Created

1. **`build-with-version.sh`**
   - Purpose: Build script with proper version tracking
   - Features:
     - Generates unique version: `dev-<timestamp>.1`
     - Updates `commondefines.js` with version numbers
     - Builds all server components
     - Creates build directory structure

2. **`VERSION-FIX-README.md`**
   - Purpose: Comprehensive documentation of the fix
   - Contents:
     - Problem explanation
     - Solution details
     - Usage instructions
     - Troubleshooting guide
     - Development workflows

3. **`docker-compose.dev-hotreload.yml`**
   - Purpose: Optional override for rapid development
   - Use Case: Quick code changes without full rebuild
   - Warning: Can cause version issues, use sparingly

4. **`rebuild.sh`**
   - Purpose: Helper script for easy rebuilds
   - Features:
     - One-command rebuild and restart
     - Clean mode (removes all data)
     - Cache control options
     - Status reporting

### ✅ Files Modified

1. **`Dockerfile.dev`**
   - **Before**: Empty image, files copied at runtime
   - **After**: 
     - Copies all source code during build
     - Runs build script with version tracking
     - Builds web-apps and sdkjs
     - Bakes everything into the image
   
   - **Key Changes**:
     ```dockerfile
     # Copy source code
     COPY core /app/DocumentServer/core
     COPY server /app/DocumentServer/server
     # ... (all source directories)
     
     # Build with version tracking
     COPY build-with-version.sh /app/DocumentServer/
     RUN /app/DocumentServer/build-with-version.sh
     
     # Build web-apps and sdkjs
     WORKDIR /app/DocumentServer/web-apps
     RUN npm install && npm run build
     ```

2. **`docker/entrypoint.sh`**
   - **Before**: Copied files on EVERY startup
   - **After**: Only copies files on FIRST run
   
   - **Key Changes**:
     ```bash
     # Check for initialization marker
     if [ ! -f "$DOCUMENT_ROOT/.initialized" ]; then
         # Copy all files (first run only)
         ...
         # Mark as initialized
         touch $DOCUMENT_ROOT/.initialized
     else
         echo "Already initialized - skipping file copy"
     fi
     ```

3. **`docker-compose.yml`**
   - **Before**: Mounted source directories as volumes
   - **After**: Only mounts persistent data volumes
   
   - **Removed**:
     ```yaml
     # These caused version mismatches:
     - ./server:/app/DocumentServer/server
     - ./web-apps:/app/DocumentServer/web-apps
     - ./sdkjs:/app/DocumentServer/sdkjs
     - ./docker/entrypoint.sh:/entrypoint.sh
     ```
   
   - **Kept**:
     ```yaml
     # Only persistent data:
     - optivise_documentserver_data:/var/www/onlyoffice
     - optivise_documentserver_logs:/var/log/onlyoffice
     - optivise_documentserver_lib:/var/lib/onlyoffice
     ```

## Technical Changes Explained

### Problem 1: File Timestamps Reset
- **Root Cause**: Files copied on every container start
- **Fix**: Only copy on first run, check for `.initialized` marker
- **Result**: File timestamps remain stable across restarts

### Problem 2: Version Number Inconsistency
- **Root Cause**: Hardcoded version `4.1.2.37` never updated
- **Fix**: Generate unique version during build: `dev-<timestamp>.1`
- **Result**: Each build has a consistent, unique version

### Problem 3: Source Volume Mounts Override Built Files
- **Root Cause**: Docker volumes mounted over built application code
- **Fix**: Remove source mounts, bake code into image
- **Result**: Built files with correct versions are used

## How the Fix Works

### Old Flow (Problematic)
```
Container Start
    ↓
Delete /var/www/onlyoffice/documentserver
    ↓
Copy from /app/DocumentServer (mounted volumes)
    ↓
Files have new timestamps
    ↓
Version check fails: "Reset file version"
    ↓
(Repeat every restart)
```

### New Flow (Fixed)
```
Docker Build
    ↓
Copy source code into image
    ↓
Generate version: dev-1731459123.1
    ↓
Update commondefines.js with version
    ↓
Build all components
    ↓
Bake into image layers

Container Start (First Time)
    ↓
Check for .initialized marker (not found)
    ↓
Copy files to /var/www/onlyoffice/documentserver
    ↓
Create .initialized marker
    ↓
Start services

Container Start (Subsequent)
    ↓
Check for .initialized marker (found)
    ↓
Skip file copy
    ↓
Start services immediately
    ↓
Version check passes ✓
```

## Version Tracking Implementation

### Build Time
```bash
# In build-with-version.sh
export PRODUCT_VERSION="dev-$(date +%s)"  # e.g., dev-1731459123
export BUILD_NUMBER=1

# Update source file
sed -i "s|const buildVersion = '.*'|const buildVersion = '${PRODUCT_VERSION}';|" \
    Common/sources/commondefines.js
```

### Runtime
```javascript
// In DocsCoServer.js
const versionMatch = openCmd.serverVersion === commonDefines.buildVersion;
// Now matches because both use the same version from build time
```

## Testing the Fix

### Step 1: Clean Existing Setup
```bash
docker-compose down -v
```

### Step 2: Build New Image
```bash
docker-compose build --no-cache documentserver
```

### Step 3: Start Services
```bash
docker-compose up -d
```

### Step 4: Verify
1. Open a document at http://localhost:9090
2. ✓ No version reset popup should appear
3. ✓ Restart container: `docker-compose restart documentserver`
4. ✓ Open document again - still no popup

## Files Overview

```
DocumentServer/
├── build-with-version.sh              # NEW - Build with version tracking
├── rebuild.sh                         # NEW - Quick rebuild helper
├── VERSION-FIX-README.md             # NEW - Comprehensive documentation
├── CHANGES-SUMMARY.md                # NEW - This file
├── docker-compose.yml                # MODIFIED - Removed source mounts
├── docker-compose.dev-hotreload.yml  # NEW - Optional hot-reload mode
├── Dockerfile.dev                    # MODIFIED - Build during image creation
└── docker/
    └── entrypoint.sh                 # MODIFIED - Only copy once
```

## Next Steps for Testing

1. **Stop Current Setup**
   ```bash
   cd "/Users/bassel/Only Office SourceCode/DocumentServer"
   docker-compose down -v
   ```

2. **Build New Image** (will take 5-10 minutes)
   ```bash
   docker-compose build --no-cache documentserver
   ```
   
   Or use the helper script:
   ```bash
   ./rebuild.sh --clean
   ```

3. **Start Services**
   ```bash
   docker-compose up -d
   ```

4. **Monitor Startup**
   ```bash
   docker-compose logs -f documentserver
   ```
   
   Look for:
   - ✓ "First run detected - copying application files..."
   - ✓ "Created initialization marker at .../initialized"
   - ✓ "Build completed successfully!"

5. **Test the Fix**
   - Open http://localhost:9090
   - Create or open a document
   - Verify NO "version reset" popup appears
   - Restart: `docker-compose restart documentserver`
   - Open document again - should work without popup

6. **Test Code Changes** (optional)
   - Make a small change to server code
   - Run: `./rebuild.sh`
   - Verify change is applied

## Success Criteria

✅ No version reset popup when opening files  
✅ Files persist across container restarts  
✅ Version numbers are consistent  
✅ Can make code changes and rebuild successfully  
✅ Faster container restarts (no file copying)

## Rollback Instructions

If you need to revert to the old setup:

```bash
# Restore old docker-compose.yml from git
git checkout docker-compose.yml

# Restore old entrypoint.sh
git checkout docker/entrypoint.sh

# Restore old Dockerfile.dev  
git checkout Dockerfile.dev

# Rebuild and restart
docker-compose down -v
docker-compose up --build -d
```

## Support

If you encounter issues:
1. Check `VERSION-FIX-README.md` for troubleshooting
2. Review build logs: `docker-compose build documentserver 2>&1 | tee build.log`
3. Check runtime logs: `docker-compose logs documentserver`
4. Verify initialization: `docker-compose exec documentserver cat /var/www/onlyoffice/documentserver/.initialized`

---

**Implementation Date**: 2025-11-13  
**Status**: Ready for testing  
**Estimated Build Time**: 5-10 minutes first build, 2-3 minutes subsequent
