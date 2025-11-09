# Binaries Directory

This directory should contain the `gltfpack` executable binary.

## Building gltfpack

Run the build script from the project root:

```bash
cd /Users/markofucek/Desktop/GLTF-Studio
chmod +x build_gltfpack.sh
./build_gltfpack.sh
```

Or build manually:

```bash
cd ~/Desktop
git clone https://github.com/zeux/meshoptimizer
git clone -b gltfpack https://github.com/zeux/basis_universal

cd meshoptimizer
cmake . -DMESHOPT_BUILD_GLTFPACK=ON \
        -DMESHOPT_GLTFPACK_BASISU_PATH=../basis_universal \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

cmake --build . --target gltfpack --config Release

# Copy to this directory
cp gltfpack /Users/markofucek/Desktop/GLTF-Studio/GLTFStudio/Resources/Binaries/
chmod +x /Users/markofucek/Desktop/GLTF-Studio/GLTFStudio/Resources/Binaries/gltfpack
```

## Verifying the Binary

```bash
# Check file type (should be universal binary)
file gltfpack

# Check architectures (should show arm64 and x86_64)
lipo -info gltfpack

# Test execution
./gltfpack --help
```

## Important Notes

- The binary is **NOT** included in the Git repository (.gitignore)
- You must build it locally before running the Xcode project
- The binary must be a **universal binary** (arm64 + x86_64) for distribution
- The binary must be **executable** (`chmod +x`)
- The binary will be copied into the app bundle during build

## File Size

The gltfpack universal binary is typically around **3-5 MB**.

## License

gltfpack is part of meshoptimizer and is licensed under the MIT License.
See `Resources/Licenses/meshoptimizer-LICENSE.txt` for details.

