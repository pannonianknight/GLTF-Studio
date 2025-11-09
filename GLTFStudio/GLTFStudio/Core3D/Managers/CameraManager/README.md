# Camera Manager

**Status:** ✅ **Complete**

## Files

- `CameraTypes.h` - Platform-agnostic data structures (Vector3, Quaternion, Presets, etc.)
- `CameraController.h` - Camera controller interface
- `CameraController.cpp` - Implementation

## Features

- ✅ Camera presets (Front, Top, Rear, custom)
- ✅ Smooth camera transitions (lerp)
- ✅ Orbit controls (pan, rotate, zoom)
- ✅ FOV calculation from focal length
- ✅ Platform-agnostic design

## Usage

See main [README.md](../../../README.md) for usage examples.

### Example: Register and use presets

```cpp
#include "Core3D/Managers/CameraManager/CameraController.h"

core3d::CameraController cameraController;

// Register presets
core3d::CameraPreset frontPreset(
    core3d::Vector3(18.0f, 3.0f, 32.0f),  // position
    core3d::Vector3(0.0f, -3.0f, 0.0f)    // lookAt
);
cameraController.registerPreset("Front", frontPreset);

// Move to preset with smooth transition
cameraController.moveToPreset("Front", true);

// Update every frame
cameraController.update(deltaTime);
```

### Example: Orbit controls

```cpp
// Enable orbit mode
cameraController.setOrbitEnabled(true);

// Apply rotation (from gesture recognizer)
cameraController.applyOrbitRotation(deltaX, deltaY);

// Apply zoom (from pinch gesture)
cameraController.applyOrbitZoom(zoomDelta);
```

