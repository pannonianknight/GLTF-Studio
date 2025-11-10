# GLTFStudio

<img width="128" height="128" alt="Icon-iOS-Default-256x256@1x" src="https://github.com/user-attachments/assets/e830bde5-57bf-4511-85b7-fa40c6a13e56" />

macOS application for glTF/GLB 3D model optimization. Targets mobile rendering engines (Filament, ARKit, ARCore) and web platforms.

## Features

- Drag & drop interface for .glb and .gltf files
- Preset-based optimization (Low/Balanced/High quality)
- Custom texture compression controls (ETC1S, UASTC via Basis Universal)
- Mesh optimization with vertex quantization (8-16 bit)
- Real-time file size and compression statistics
- Animation detection with smart optimization
- Live processing logs

## 📋 Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (M1/M2/M3) or Intel processor

## 🛠️ Installation

### Option 1: Download Pre-built App (Recommended)
1. Download the latest release from [Releases](https://github.com/pannonianknight/GLTF-Studio/releases)
2. Open the DMG file
3. Drag GLTFStudio.app to Applications folder
4. Right-click and select "Open" on first launch (macOS Gatekeeper)

### Option 2: Build from Source

#### Prerequisites
- Xcode 15.0+
- Command Line Tools: `xcode-select --install`

#### Build gltfpack binary:
```bash
cd ~/Desktop
git clone https://github.com/zeux/meshoptimizer
git clone -b gltfpack https://github.com/zeux/basis_universal
cd meshoptimizer
cmake . -DMESHOPT_BUILD_GLTFPACK=ON \
        -DMESHOPT_GLTFPACK_BASISU_PATH=../basis_universal \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
cmake --build . --target gltfpack --config Release
```

#### Build the App:
1. Clone this repository:
   ```bash
   git clone https://github.com/pannonianknight/GLTF-Studio.git
   cd GLTF-Studio
   ```

2. Run the build script (automatically builds gltfpack):
   ```bash
   ./build_gltfpack.sh
   ```
   
   Or copy manually if you already have gltfpack:
   ```bash
   cp ~/Desktop/meshoptimizer/gltfpack GLTFStudio/GLTFStudio/Resources/Binaries/
   chmod +x GLTFStudio/GLTFStudio/Resources/Binaries/gltfpack
   ```

3. Open `GLTFStudio/GLTFStudio/GLTFStudio.xcodeproj` in Xcode

4. Add files to project:
   - Right-click on GLTFStudio folder → Add Files
   - Select Models, Services, Views, Resources folders
   - Uncheck "Copy items if needed"
   - Check "Add to targets: GLTFStudio"

5. Select your development team in Signing & Capabilities

6. Build and run (⌘R)

## 📖 Usage

### Quick Start
1. Launch GLTFStudio
2. Drag & drop your `.glb` or `.gltf` file
3. Select a preset (Low/Balanced/High)
4. Click "Optimize"
5. Find optimized file in the same directory as input

### Presets Explained

| Preset | Use Case | Compression | Quality |
|--------|----------|-------------|---------|
| **Low Quality** | Maximum compression for low-end mobile | Aggressive | ~10-20% of original |
| **Balanced** | General mobile/web use | Moderate | ~30-40% of original |
| **High Quality** | Desktop/high-end mobile | Conservative | ~50-70% of original |
| **Custom** | Fine-tuned control | Manual | Variable |

### Custom Options

#### Texture Compression
- **Format**: 
  - `ETC1S` - Best compression, good quality (recommended for mobile)
  - `UASTC` - Higher quality, larger files (for high-end devices)
  - `None` - Keep original textures
- **Quality**: 1-255 (higher = better quality, larger files)
- **Max Dimension**: Resize large textures (256/512/1024/2048)
- **Power-of-Two**: Force textures to POT dimensions for older GPUs

#### Mesh Optimization
- **Mesh Compression**: Enable/disable mesh compression
- **Vertex Position**: 8-16 bits (higher = better precision)
- **Texture Coords**: 8-16 bits
- **Normals**: 8-16 bits

## Target Platforms

- iOS/Android (Filament, ARKit, ARCore)
- WebGL/WebGPU (Three.js, Babylon.js)
- Game Engines (Unity, Unreal, Godot)

## Technical Details

Built with Swift 6.0 and SwiftUI for macOS 13.0+.

### Dependencies
- [meshoptimizer](https://github.com/zeux/meshoptimizer) - Mesh optimization (MIT License)
- [basis_universal](https://github.com/BinomialLLC/basis_universal) - Texture compression (Apache 2.0)
- gltfpack - Command-line optimization tool (bundled)

### Optimization Pipeline
1. Model analysis (animations, skins, mesh count)
2. Vertex cache optimization and overdraw reduction
3. Attribute quantization (8-16 bit precision)
4. Mesh compression codec
5. Basis Universal texture compression (KTX2 format)
6. Texture resizing and power-of-two normalization

## Known Issues

- Large files (>100MB) may take several minutes to process
- First run may show security warning (right-click > Open to bypass)
- Texture compression requires app sandbox entitlements

## Planned Features

- Filament-powered 3D preview (original vs optimized comparison)
- HDR environment map editing tools
- Batch processing
- Draco compression support
- CLI version

## License

MIT License - see [LICENSE](LICENSE) file.

### Third-Party Components
- **meshoptimizer** - MIT License (Arseny Kapoulkine)
- **basis_universal** - Apache 2.0 License (Binomial LLC)

Full license texts available in `Resources/Licenses/` directory.

## Links

- GitHub: [GLTF-Studio](https://github.com/pannonianknight/GLTF-Studio)
- Issues: [Report a bug](https://github.com/pannonianknight/GLTF-Studio/issues)
