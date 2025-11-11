#!/bin/bash

# Build Release verzija GLTFStudio aplikacije

set -e  # Exit on error

echo "🔨 Building GLTFStudio Release..."

# Xcode path
XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

# Project paths
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/GLTFStudio.xcodeproj"
SCHEME="GLTFStudio"
CONFIG="Release"

# Build directory
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="GLTFStudio.app"

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"

# Build Release
echo "🚀 Building Release configuration..."
"$XCODEBUILD" \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    clean build

# Find the built app
BUILT_APP="$BUILD_DIR/DerivedData/Build/Products/$CONFIG/$APP_NAME"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed - app not found at: $BUILT_APP"
    exit 1
fi

echo "✅ Build successful!"

# Copy to project root for easy access
OUTPUT_DIR="$PROJECT_DIR/Release"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
cp -R "$BUILT_APP" "$OUTPUT_DIR/"

echo "📦 App copied to: $OUTPUT_DIR/$APP_NAME"

# Verify gltfpack is included
if [ -f "$OUTPUT_DIR/$APP_NAME/Contents/Resources/gltfpack" ]; then
    echo "✅ gltfpack binary included"
else
    echo "⚠️  Warning: gltfpack binary not found in bundle"
fi

# Check if gltfpack is in Binaries folder
if [ -f "$OUTPUT_DIR/$APP_NAME/Contents/Resources/Binaries/gltfpack" ]; then
    echo "✅ gltfpack in Binaries folder"
fi

# Create ZIP archive
echo "📦 Creating ZIP archive..."
cd "$OUTPUT_DIR"
zip -r "GLTFStudio.zip" "$APP_NAME" -x "*.DS_Store"
echo "✅ Created: $OUTPUT_DIR/GLTFStudio.zip"

# Print summary
echo ""
echo "✨ Done!"
echo "   App location: $OUTPUT_DIR/$APP_NAME"
echo "   ZIP archive:  $OUTPUT_DIR/GLTFStudio.zip"
echo ""
echo "To run: open $OUTPUT_DIR/$APP_NAME"
echo "To install: Drag GLTFStudio.app to /Applications"

