#!/bin/bash
set -e

# Build script for gltfpack universal binary (Intel + Apple Silicon)
# This script downloads and builds meshoptimizer with gltfpack support

echo "🚀 Building gltfpack universal binary for macOS..."

# Configuration
TEMP_DIR="/tmp/gltfpack-build"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$PROJECT_DIR/GLTFStudio/Resources/Binaries"

# Clean up previous build
if [ -d "$TEMP_DIR" ]; then
    echo "🧹 Cleaning up previous build..."
    rm -rf "$TEMP_DIR"
fi

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Clone repositories
echo "📦 Cloning meshoptimizer..."
git clone https://github.com/zeux/meshoptimizer.git

echo "📦 Cloning basis_universal (gltfpack branch)..."
git clone -b gltfpack https://github.com/zeux/basis_universal.git

# Build gltfpack
cd meshoptimizer
echo "🔨 Building gltfpack..."

cmake . \
    -DMESHOPT_BUILD_GLTFPACK=ON \
    -DMESHOPT_GLTFPACK_BASISU_PATH=../basis_universal \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

cmake --build . --target gltfpack --config Release

# Verify build
if [ ! -f "gltfpack" ]; then
    echo "❌ Error: gltfpack binary not found after build"
    exit 1
fi

# Check architecture
echo ""
echo "📋 Binary information:"
file gltfpack
lipo -info gltfpack

# Copy to project
echo ""
echo "📁 Copying to project..."
mkdir -p "$OUTPUT_DIR"
cp gltfpack "$OUTPUT_DIR/"
chmod +x "$OUTPUT_DIR/gltfpack"

# Verify
echo ""
echo "✅ Build complete!"
echo "Binary location: $OUTPUT_DIR/gltfpack"
echo ""
echo "Testing binary..."
"$OUTPUT_DIR/gltfpack" --help || true

# Clean up
echo ""
echo "🧹 Cleaning up temporary files..."
cd "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

echo ""
echo "✨ Done! You can now build the Xcode project."

