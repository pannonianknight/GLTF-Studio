# Filament Integration Plan

## Status: IN PROGRESS

Building 3D preview window with Filament for macOS.

---

## Required Libraries (from ~/Desktop/filament/out/cmake-release/)

### Core Filament:
- `filament/libfilament.a` (3.2MB)
- `libs/backend/libbackend.a`
- `libs/filabridge/libfilabridge.a`
- `libs/filaflat/libfilaflat.a`

### glTF Support:
- `libs/gltfio/libgltfio.a`
- `libs/gltfio/libgltfio_core.a`
- `libs/gltfio/libuberarchive.a`

### Utilities:
- `libs/utils/libutils.a`
- `libs/math/libmath.a`
- `libs/image/libimage.a`
- `libs/ktxreader/libktxreader.a`

### Total: ~15-20 libraries

---

## Include Paths:

```
~/Desktop/filament/filament/include
~/Desktop/filament/libs/gltfio/include
~/Desktop/filament/libs/utils/include
~/Desktop/filament/libs/math/include
~/Desktop/filament/libs/image/include
```

---

## Adaptation Steps:

### 1. UIKit → AppKit Changes:
- `UIView` → `NSView`
- `UIColor` → `NSColor`
- `UIPinchGestureRecognizer` → `NSMagnificationGestureRecognizer`
- `UIPanGestureRecognizer` → `NSPanGestureRecognizer`

### 2. MTKView (isti za iOS i macOS):
- `MTKView` works same way
- `MTKViewDelegate` methods identical

### 3. FilamentRenderer structure:
```
FilamentRendererMac (NSView)
  ├─ MTKView (Metal rendering)
  ├─ Filament::Engine
  ├─ Filament::Scene
  ├─ Filament::Renderer
  ├─ Filament::Camera
  ├─ gltfio::AssetLoader
  └─ Core3D managers (Camera/Animation/Material)
```

---

## Xcode Configuration:

### Build Settings:
```
Header Search Paths:
  ~/Desktop/filament/filament/include
  ~/Desktop/filament/libs/*/include
  
Library Search Paths:
  ~/Desktop/filament/out/cmake-release/**
  
Other Linker Flags:
  -lc++
  -ObjC
  
```

### Link Binary With Libraries:
- Add all .a files
- Metal.framework
- MetalKit.framework
- QuartzCore.framework

---

## Files to Create:

1. `Filament/FilamentRendererMac.h` ✓
2. `Filament/FilamentRendererMac.mm` (adapt from iOS)
3. `Filament/FilamentViewMac.swift` (NSView wrapper)
4. `Views/FilamentPreviewWindow.swift` (SwiftUI window)
5. `Models/ModelStats.swift` (stats structure)
6. `GLTFStudio-Bridging-Header.h` (C++ bridging)

---

## Integration Timeline:

**Phase 1 (1-2h):** Basic setup
- Copy libraries
- Setup build settings
- Create bridging header
- Test compile

**Phase 2 (2-3h):** Renderer adaptation
- Adapt FilamentRenderer for macOS
- Fix UIKit → AppKit
- Test basic rendering

**Phase 3 (1-2h):** UI integration
- Create preview window
- Wire up to ContentView
- Add model comparison

**Phase 4 (1h):** Stats & Polish
- Extract model stats
- FPS counter
- Memory tracking

**TOTAL: 5-8 hours**

---

## Current Status:

- [x] Feature branch created
- [x] Core3D copied
- [x] FilamentRenderer files copied
- [x] macOS header created
- [ ] Adapt .mm file (NEXT)
- [ ] Link libraries
- [ ] Test compile

---

Next: Start adapting FilamentRenderer.mm for macOS...

