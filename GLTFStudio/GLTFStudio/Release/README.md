# GLTF Studio - Pre-built Release

This folder contains the pre-built GLTF Studio application ready to use on macOS.

## Download & Install

### Quick Start

1. **Download** `GLTFStudio.zip`
2. **Extract** the zip file (double-click)
3. **Open** the app:
   - **First time:** Right-click `GLTFStudio.app` → **Open**
   - Click **Open** in the security dialog
   - **Next times:** Double-click to open normally

4. **Install** (optional):
   - Drag `GLTFStudio.app` to your `/Applications` folder

## System Requirements

- **macOS:** 14.0 (Sonoma) or later
- **Architecture:** Universal (works on both Apple Silicon and Intel Macs)
- **Disk Space:** ~10 MB

## Why "Right-click → Open" on first launch?

The app is **code-signed** but **not notarized** with Apple. This is normal for open-source apps without a paid Apple Developer subscription. macOS Gatekeeper requires you to explicitly allow the app on first launch.

### Security Notes

✅ The app is code-signed  
✅ Open source - you can review the code  
✅ No internet access required  
✅ Sandboxed - limited file system access  
✅ Only accesses files you explicitly select  

## What's Included

```
GLTFStudio.app
├── Contents/
    ├── MacOS/
    │   └── GLTFStudio        # Main executable
    └── Resources/
        ├── gltfpack          # Optimization binary (5.7 MB)
        ├── Assets.car        # UI assets
        └── *.png             # Icons
```

## File Size

- **Uncompressed:** ~10 MB
- **ZIP archive:** ~6 MB
- **gltfpack binary:** 5.7 MB (universal arm64 + x86_64)

## Usage

1. Launch GLTF Studio
2. Drag & drop a `.glb` or `.gltf` file
3. Choose a preset (Low/Balanced/High/Custom)
4. Click "Optimize"
5. Optimized file is saved next to the original

See the [main README](../README.md) for detailed usage instructions.

## Building from Source

If you prefer to build the app yourself, see the [build instructions](../README.md#building) in the main README.

## Troubleshooting

### "Cannot open because developer cannot be verified"

This is expected. Right-click → Open bypasses this check.

### "App is damaged and can't be opened"

macOS sometimes quarantines downloaded apps. Remove the quarantine:

```bash
xattr -cr /path/to/GLTFStudio.app
```

### App won't launch

Check that you're running macOS 14.0 or later:

```bash
sw_vers
```

## Support

- **Issues:** [GitHub Issues](https://github.com/pannonianknight/GLTF-Studio/issues)
- **Source Code:** [GitHub Repository](https://github.com/pannonianknight/GLTF-Studio)

---

**Version:** 1.0.0  
**Build Date:** November 2025  
**macOS Target:** 14.0+  
**License:** MIT

