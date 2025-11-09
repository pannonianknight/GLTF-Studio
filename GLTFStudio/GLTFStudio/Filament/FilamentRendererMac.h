//
//  FilamentRendererMac.h
//  GLTFStudio
//
//  Created on 2025-11-09.
//  macOS adaptation of FilamentRenderer
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Camera preset for easy camera positioning
typedef struct {
    float posX, posY, posZ;
    float targetX, targetY, targetZ;
} CameraPreset;

/// Model statistics extracted from glTF
typedef struct {
    int vertexCount;
    int triangleCount;
    int meshCount;
    int materialCount;
    int textureCount;
    size_t estimatedVRAM;
} ModelStats;

@interface FilamentRendererMac : NSView

- (instancetype)initWithFrame:(NSRect)frame;

// Model loading
- (BOOL)loadModelFromPath:(NSString *)path;
- (BOOL)loadModelFromData:(NSData *)data;
- (ModelStats)getModelStats;

// Camera controls
- (void)setOrbitControlsEnabled:(BOOL)enabled;
- (void)resetCamera;
- (void)fitCameraToModel;

// Camera presets
- (void)moveCameraToFront;
- (void)moveCameraToTop;
- (void)moveCameraToRear;

// Background
- (void)setBackgroundColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

// Debug
- (void)toggleDebugAxis;
- (BOOL)isDebugAxisVisible;

// Animation
- (NSInteger)getAnimationCount;
- (nullable NSString *)getAnimationNameAtIndex:(NSInteger)index;
- (void)playAnimationAtIndex:(NSInteger)index;
- (void)stopAnimation;

// Performance
- (float)getCurrentFPS;
- (size_t)getCurrentMemoryUsage;

@end

NS_ASSUME_NONNULL_END

