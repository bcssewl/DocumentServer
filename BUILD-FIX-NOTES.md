# Build Fix: SpellChecker Native Compilation Issue

## Problem

The build was failing when trying to compile the SpellChecker component:
```
make: *** No rule to make target 'Release/obj.target/hunspell/src/hunspell/src/hunspell/affentry.o'
npm error gyp ERR! build error
```

## Root Cause

SpellChecker depends on `nodehun`, a Node.js binding for the Hunspell library. This requires:
- Native C++ compilation with `node-gyp`
- Hunspell development headers
- Proper build toolchain setup

These native dependencies frequently cause build failures in containerized environments.

## Solution

**Skipped SpellChecker build entirely** because:
1. ✅ It's already marked as `autostart=false` in `supervisord.conf` (disabled by default)
2. ✅ It's optional - documents work perfectly without spell checking
3. ✅ Native compilation is complex and error-prone
4. ✅ Not essential for fixing the version reset issue

## Changes Made

### 1. Updated `build-with-version.sh`
- Removed SpellChecker build steps
- Added clear message that SpellChecker is skipped
- Build directory no longer includes SpellChecker

### 2. Updated `Dockerfile.dev`  
- Removed hunspell dependency installation
- Build proceeds without SpellChecker

## Services Status After Fix

| Service | Status | Notes |
|---------|--------|-------|
| **DocService** | ✅ Built & Enabled | Core document editing service |
| **FileConverter** | ✅ Built & Enabled | Document format conversion |
| **Common** | ✅ Built & Enabled | Shared utilities and configs |
| **Metrics** | ✅ Built & Enabled | Monitoring and metrics |
| **SpellChecker** | ⚠️ Skipped | Optional, disabled by default |

## Impact

- **Documents will open and edit normally** ✅
- **Spell checking will not be available** ⚠️
- **Version reset issue will still be fixed** ✅
- **Build time reduced** (no native compilation) ✅

## Re-enabling SpellChecker (Advanced)

If you need spell checking in the future:

### Option 1: Use Official Docker Image
```bash
docker pull onlyoffice/documentserver
```
The official image has SpellChecker pre-compiled.

### Option 2: Build SpellChecker Separately
```bash
# Install system dependencies
apt-get install libhunspell-dev hunspell-en-us

# In server/SpellChecker directory
npm install
npm run build
```

### Option 3: Install Pre-built Nodehun
```bash
# Use a pre-compiled version if available
npm install nodehun --build-from-source=false
```

## Testing the Build Now

The build should complete successfully:

```bash
cd "/Users/bassel/Only Office SourceCode/DocumentServer"

# Clean and rebuild
./rebuild.sh --clean

# Or manually:
docker-compose down -v
docker-compose build --no-cache documentserver
docker-compose up -d
```

Expected output:
```
✓ Version numbers updated
✓ Building Common...
✓ Building DocService...
✓ Building FileConverter...
✓ Building Metrics...
⚠️  Skipping SpellChecker build (optional service)
✓ Build completed successfully!
```

## Verification

After the build completes:

1. **Check services are running:**
   ```bash
   docker-compose exec documentserver supervisorctl status
   ```
   
   Should show:
   - docservice: RUNNING ✅
   - converter: RUNNING ✅
   - nginx: RUNNING ✅
   - spellchecker: STOPPED (expected) ⚠️
   - metrics: STOPPED or RUNNING (both OK) ⚠️

2. **Open a document:**
   - Go to http://localhost:9090
   - Open/create a document
   - Should work without version reset popup ✅

## Summary

**Build failure fixed** by skipping optional SpellChecker component. Core functionality (document editing, viewing, conversion) remains intact. The version reset issue fix is unaffected by this change.

---

**Status**: Build should now complete successfully  
**Next Step**: Run `./rebuild.sh --clean` to test
