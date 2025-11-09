#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// ============================================================================
// CAMERA PRESET STRUCTURE - Eksponirana za lakše podešavanje
// ============================================================================
typedef struct {
    float posX, posY, posZ;      // Pozicija kamere
    float targetX, targetY, targetZ;  // Točka gdje kamera gleda
} CameraPreset;

@interface FilamentRenderer : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)pinch:(UIPinchGestureRecognizer *)gesture;

// Metoda za mijenjanje pozadinske boje (RGBA 0-1.0)
- (void)setBackgroundColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

// Orbit kontrole: enable/disable iz Swift-a
- (void)setOrbitControlsEnabled:(BOOL)enabled;

// Camera preset metode
- (void)moveToPresetFront;
- (void)moveToPresetTop;
- (void)moveToPresetRear;

// Metoda za eksplicitno postavljanje preset pozicije (za fine-tuning)
- (void)setPreset:(const char *)presetName position:(CameraPreset)preset;

// Debug Axis toggle
- (void)toggleDebugAxis;
- (BOOL)isDebugAxisVisible;

// Animation control
- (NSInteger)getAnimationCount;
- (nullable NSString *)getAnimationNameAtIndex:(NSInteger)index;
- (void)playAnimationAtIndex:(NSInteger)index;

// Material debug tools (prototype only)
- (void)randomizeCarPaint;
- (void)inspectMaterials;

// Memory benchmark tools
- (void)loadProceduralCube;

// Runtime SGSR control
- (void)setDynamicResolutionScale:(float)scale;
- (float)getCurrentResolutionScale;

@end

NS_ASSUME_NONNULL_END
