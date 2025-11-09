# Material Manager

**Status:** ✅ **Complete**

## Files

- `MaterialTypes.h` - Material structures (PBR, colors, presets)
- `MaterialManager.h` - Material manager interface
- `MaterialManager.cpp` - Implementation

## Features

- ✅ Dynamic paint color change
- ✅ PBR property control (metallic, roughness, clearCoat, anisotropy)
- ✅ Texture path management
- ✅ 12 material presets (GlossyPaint, Chrome, Leather, Glass, etc.)
- ✅ Batch operations (apply color to multiple parts)
- ✅ Platform-agnostic design

## Material Presets

### Car Paint:
- **GlossyPaint** - Shiny car paint (metallic: 0.8, roughness: 0.2, clearCoat: 1.0)
- **MattePaint** - Matte finish (metallic: 0.0, roughness: 0.8)
- **MetallicPaint** - Metallic flake (metallic: 0.9, clearCoat: 0.8)

### Wheels:
- **Chrome** - Mirror finish (metallic: 1.0, roughness: 0.05)
- **AluminumAlloy** - Brushed aluminum (metallic: 1.0, roughness: 0.4)

### Interior:
- **Leather** - Leather seats (roughness: 0.6)
- **Fabric** - Fabric seats (roughness: 0.9)
- **Plastic** - Dashboard plastic (roughness: 0.5)

### Glass:
- **Glass** - Clear glass (alpha: 0.3)
- **TintedGlass** - Dark tinted (alpha: 0.5)

### Misc:
- **Rubber** - Tires (roughness: 0.85, dark)
- **Carbon** - Carbon fiber (anisotropy: 0.8)

## Usage

See main [README.md](../../../README.md) for usage examples.

### Example: Change car paint color

```cpp
#include "Core3D/Managers/MaterialManager/MaterialManager.h"

core3d::MaterialManager materialManager;

// Apply red glossy paint
materialManager.applyPreset("Body", core3d::MaterialPreset::GlossyPaint);
materialManager.setBaseColor("Body", 1.0f, 0.0f, 0.0f);  // Red

// Get config to apply to Filament
const core3d::MaterialConfig* bodyMaterial = materialManager.getMaterial("Body");
```

### Example: Customize material properties

```cpp
// Custom material
materialManager.setBaseColor("Body", 0.2f, 0.4f, 0.8f);  // Blue
materialManager.setMetallic("Body", 0.9f);
materialManager.setRoughness("Body", 0.1f);
materialManager.setClearCoat("Body", 1.0f, 0.05f);
```


