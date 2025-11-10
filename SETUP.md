# Build Instructions

## Requirements

- Xcode 15.0+
- macOS 13.0+
- Command Line Tools: `xcode-select --install`

## Build Steps

### 1. Clone Repository

```bash
git clone https://github.com/pannonianknight/GLTF-Studio.git
cd GLTF-Studio
```

### 2. Build gltfpack Binary

```bash
./build_gltfpack.sh
```

This downloads and compiles meshoptimizer with gltfpack support (universal binary for Intel + Apple Silicon).

### 3. Open Project

```bash
open GLTFStudio/GLTFStudio/GLTFStudio.xcodeproj
```

### 4. Configure Signing

1. Select GLTFStudio project (blue icon)
2. Select GLTFStudio target
3. Signing & Capabilities → Select your Team

### 5. Build

```
Cmd+B
```

### 6. Run

```
Cmd+R
```

## Distribution

### Create Standalone App

**Option 1: Archive**
```
Product → Archive → Distribute App → Copy App
```

**Option 2: Terminal**
```bash
cd GLTFStudio/GLTFStudio
xcodebuild -project GLTFStudio.xcodeproj \
           -scheme GLTFStudio \
           -configuration Release \
           clean archive
```

App location: `~/Library/Developer/Xcode/Archives/`

