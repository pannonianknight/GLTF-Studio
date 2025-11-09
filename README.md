# GLTFStudio

<div align="center">
  <h3>🎨 Professional glTF/GLB Optimization for macOS</h3>
  <p>User-friendly GUI for optimizing 3D models for mobile and web platforms</p>
</div>

## 🚀 Features

- **Drag & Drop Interface** - Simple file selection for glTF and GLB files
- **Preset System** - Quick optimization with Low/Balanced/High quality presets
- **Custom Controls** - Fine-tune texture compression and mesh quantization
- **Real-time Stats** - View file size reduction and compression ratio
- **Mobile-Ready** - Optimized for iOS/Android rendering with Filament
- **Texture Compression** - ETC1S and UASTC formats via Basis Universal
- **Mesh Optimization** - Advanced vertex quantization and compression

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

## 🎯 Target Platforms

GLTFStudio is optimized for preparing models for:
- **iOS/Android** (ARCore, ARKit, Filament)
- **WebGL/WebGPU** (Three.js, Babylon.js)
- **Game Engines** (Unity, Unreal, Godot)

## 📊 Technical Details

### Powered By
- [meshoptimizer](https://github.com/zeux/meshoptimizer) - Mesh optimization library
- [basis_universal](https://github.com/BinomialLLC/basis_universal) - Texture compression
- [gltfpack](https://github.com/zeux/meshoptimizer/tree/master/gltf) - glTF optimization CLI

### Optimization Pipeline
1. **Mesh Processing**: Vertex cache optimization, overdraw reduction, vertex fetch optimization
2. **Attribute Quantization**: Reduce vertex attribute precision
3. **Mesh Compression**: Apply mesh compression codec
4. **Texture Compression**: Basis Universal ETC1S/UASTC encoding
5. **Texture Resizing**: Downscale textures to target resolution
6. **File Packing**: Optimize glTF structure and remove unused data

## 🐛 Known Issues

- Large files (>100MB) may take several minutes to process
- First run may show security warning (right-click > Open to bypass)
- Progress bar shows indeterminate progress (no percentage yet)
- Texture compression requires proper entitlements (included in build)

## 🗺️ Roadmap

- [ ] Batch processing support
- [ ] Real-time 3D preview
- [ ] Draco compression support
- [ ] Comparison viewer (before/after)
- [ ] Animation optimization
- [ ] CLI version for automation
- [ ] Cloud processing option

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses
- meshoptimizer - MIT License
- basis_universal - Apache 2.0 License
- gltf-transform - MIT License

See `Resources/Licenses/` directory for full license texts.

## 🙏 Acknowledgments

- [Arseny Kapoulkine](https://github.com/zeux) for meshoptimizer and gltfpack
- [Binomial LLC](https://github.com/BinomialLLC) for Basis Universal
- [Don McCurdy](https://github.com/donmccurdy) for glTF Transform
- Khronos Group for the glTF specification

## 📧 Contact

- GitHub Issues: [Report a bug](https://github.com/pannonianknight/GLTF-Studio/issues)
- GitHub Repo: [GLTF-Studio](https://github.com/pannonianknight/GLTF-Studio)

---

<div align="center">
  Made with ❤️ for the 3D community
</div>
