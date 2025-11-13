#!/bin/bash
set -e

echo "Generating AllFonts.js..."

# Set library path to include our extracted libraries
export LD_LIBRARY_PATH=/app/prebuilt-tools/bin:$LD_LIBRARY_PATH

# Create output directories if they don't exist
mkdir -p /app/sdkjs/common/Images
mkdir -p /app/server/FileConverter/bin
mkdir -p /app/fonts

# Generate AllFonts.js
/app/prebuilt-tools/allfontsgen \
  --input="/app/core-fonts" \
  --allfonts-web="/app/sdkjs/common/AllFonts.js" \
  --allfonts="/app/server/FileConverter/bin/AllFonts.js" \
  --images="/app/sdkjs/common/Images" \
  --selection="/app/server/FileConverter/bin/font_selection.bin" \
  --output-web="/app/fonts" \
  --use-system="true"

echo "AllFonts.js generated successfully!"

echo "Generating presentation themes..."

# Generate themes
/app/prebuilt-tools/allthemesgen \
  --converter-dir="/app/prebuilt-tools/bin" \
  --src="/app/sdkjs/slide/themes" \
  --output="/app/sdkjs/common/Images"

echo "Themes generated successfully!"

echo "All generation tasks completed!"
