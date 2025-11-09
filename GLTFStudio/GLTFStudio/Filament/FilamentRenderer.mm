/*
 * FilamentRenderer.mm
 *
 * THIS FILE IS A "BRIDGE" BETWEEN SWIFT AND C++ FILAMENT
 *
 * Structure:
 * Swift (ViewController.swift)
 *   → Swift (FilamentView.swift - wrapper)
 *     → Objective-C++ (FilamentRenderer.mm - this file)
 *       → C++ (Filament library)
 *
 * FilamentRenderer is a UIView subclass that:
 * 1. Creates MTKView (Metal rendering surface)
 * 2. Wraps Filament Engine, Scene, Camera, Renderer
 * 3. Loads and renders 3D models (GLB format)
 */

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "FilamentRenderer.h"

// Core3D includes (from root-level submodule)
#include "../../Core3D/Core3D/Managers/AnimationManager/AnimationController.h"
#include "../../Core3D/Core3D/Managers/CameraManager/CameraController.h"
#include "../../Core3D/Core3D/Managers/MaterialManager/MaterialManager.h"

// Filament C++ library includes
#include "filament/Engine.h"
#include "filament/Renderer.h"
#include "filament/Scene.h"
#include "filament/View.h"
#include "filament/Camera.h"
#include "filament/Viewport.h"
#include "filament/TransformManager.h"
#include "filament/LightManager.h"
#include "filament/RenderableManager.h"
#include "filament/Color.h"
#include "filament/Texture.h"
#include "filament/TextureSampler.h"
#include "filament/Box.h"
#include "filament/Skybox.h"
#include "filament/ColorGrading.h"
#include "filament/ToneMapper.h"
#include "filament/IndirectLight.h"
#include "filament/VertexBuffer.h"
#include "filament/IndexBuffer.h"
#include "filament/Material.h"
#include "math/quat.h"
#include "utils/EntityManager.h"
#include "gltfio/AssetLoader.h"
#include "gltfio/FilamentAsset.h"
#include "gltfio/MaterialProvider.h"
#include "gltfio/ResourceLoader.h"
#include "gltfio/TextureProvider.h"
#include "gltfio/Animator.h"
#include "gltfio/materials/uberarchive.h"
#include "image/Ktx1Bundle.h"
#include "ktxreader/Ktx1Reader.h"

using namespace filament;
using namespace utils;

// ============================================================================
// MARK: - Constants
// ============================================================================

// ============================================================================
// SHADOW CONFIGURATION - Konfiguracija sjena
// ============================================================================
const bool SHADOWS_ENABLED = true;                 // Uključi/isključi sjene (true/false)
const float SUN_LIGHT_INTENSITY = 110000.0f;       // Intenzitet sunčevog svjetla (veća vrijednost = svjetlije)
const float SUN_LIGHT_DIRECTION_X = 0.6f;          // Smjer sunca X (-1 do 1)
const float SUN_LIGHT_DIRECTION_Y = -1.0f;         // Smjer sunca Y (-1 do 1, -1 = odozgo prema dolje)
const float SUN_LIGHT_DIRECTION_Z = -0.8f;         // Smjer sunca Z (-1 do 1)

// ============================================================================
// ANGLE CONVERSION - UNUSED (Commented out to reduce binary size)
// ============================================================================
// const float DEG_TO_RAD = M_PI / 180.0f;
// const float ANGLE_0 = 0.0f;
// const float ANGLE_5 = 5 * DEG_TO_RAD;
// const float ANGLE_10 = 10 * DEG_TO_RAD;
// const float ANGLE_15 = 15 * DEG_TO_RAD;
// const float ANGLE_20 = 20 * DEG_TO_RAD;
// const float ANGLE_25 = 25 * DEG_TO_RAD;
// const float ANGLE_30 = M_PI / 6.0f;
// const float ANGLE_35 = 35 * DEG_TO_RAD;
// const float ANGLE_40 = 40 * DEG_TO_RAD;
// const float ANGLE_45 = M_PI / 4.0f;
// const float ANGLE_50 = 50 * DEG_TO_RAD;
// const float ANGLE_55 = 55 * DEG_TO_RAD;
// const float ANGLE_60 = M_PI / 3.0f;
// const float ANGLE_65 = 65 * DEG_TO_RAD;
// const float ANGLE_70 = 70 * DEG_TO_RAD;
// const float ANGLE_75 = 75 * DEG_TO_RAD;
// const float ANGLE_80 = 80 * DEG_TO_RAD;
// const float ANGLE_85 = 85 * DEG_TO_RAD;
// const float ANGLE_90 = M_PI / 2.0f;
// const float ANGLE_2 = 2 * DEG_TO_RAD;
// const float ANGLE_72 = 72 * DEG_TO_RAD;

// Orbit control configuration
const float MIN_DISTANCE = 2.0f;
const float MAX_DISTANCE = 50.0f;
math::float3 orbitTarget = math::float3{0.0f, 0.0f, 0.0f};

// Camera lens configuration
const float FOCAL_LENGTH_MM = 80.0f;    // 80mm lens
const float SENSOR_HEIGHT_MM = 24.0f;   // Full-frame sensor height (vertical)

// Helper function to calculate vertical FOV from focal length and sensor height
inline float calculateVerticalFOV(float focalLengthMM, float sensorHeightMM) {
    // FOV = 2 * atan(sensorHeight / (2 * focalLength))
    float fovRadians = 2.0f * atanf(sensorHeightMM / (2.0f * focalLengthMM));
    float fovDegrees = fovRadians * 180.0f / M_PI;
    return fovDegrees;
}

// ============================================================================
// MARK: - Private Interface
// ============================================================================

@interface FilamentRenderer () <MTKViewDelegate>

// Core Filament components
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic) Engine *engine;
@property (nonatomic) Renderer *renderer;
@property (nonatomic) Scene *scene;
@property (nonatomic) View *view;
@property (nonatomic) Camera *camera;
@property (nonatomic) SwapChain *swapChain;

// Asset management
@property (nonatomic) gltfio::FilamentAsset *asset;
@property (nonatomic) gltfio::FilamentAsset *debugAxisAsset;
@property (nonatomic) gltfio::FilamentAsset *floorAsset;
@property (nonatomic) gltfio::AssetLoader *assetLoader;
@property (nonatomic) gltfio::ResourceLoader *resourceLoader;
@property (nonatomic) gltfio::MaterialProvider *materialProvider;
@property (nonatomic) gltfio::TextureProvider *textureProvider;

// Animation
@property (nonatomic) gltfio::Animator *animator;
@property (nonatomic) core3d::AnimationController *animationController;

// Core3D Camera
@property (nonatomic) core3d::CameraController *cameraController;

// Core3D Material
@property (nonatomic) core3d::MaterialManager *materialManager;

// Rendering components
@property (nonatomic) Skybox *skybox;
@property (nonatomic) ColorGrading *colorGrading;
@property (nonatomic) IndirectLight *indirectLight;
@property (nonatomic) Texture *iblTexture;
@property (nonatomic, strong) NSData *iblTextureData;  // Keep data alive
@property (nonatomic) image::Ktx1Bundle *ktxBundle;    // Keep bundle alive

// Background color interpolation
@property (nonatomic) float targetBgRed;
@property (nonatomic) float targetBgGreen;
@property (nonatomic) float targetBgBlue;
@property (nonatomic) float targetBgAlpha;
@property (nonatomic) float currentBgRed;
@property (nonatomic) float currentBgGreen;
@property (nonatomic) float currentBgBlue;
@property (nonatomic) float currentBgAlpha;

// Camera animation
@property (nonatomic) BOOL isCameraMoving;
@property (nonatomic) math::float3 camTargetPos;
@property (nonatomic) math::float3 camTargetLookAt;
@property (nonatomic) math::float3 camCurrentPos;
@property (nonatomic) math::float3 camCurrentLookAt;

// Orbit controls
@property (nonatomic) math::quatf orbitRotation;
@property (nonatomic) float currentOrbitDistance;
@property (nonatomic) BOOL orbitControlsEnabled;

// Debug axis visibility
@property (nonatomic) BOOL debugAxisVisible;

// Current resolution scale
@property (nonatomic) float currentResolutionScale;

// Animation playback state
@property (nonatomic) BOOL isAnimationPlaying;
@property (nonatomic) NSInteger currentAnimationIndex;
@property (nonatomic) float animationElapsedTime;
@property (nonatomic) float currentAnimationDuration;
@property (nonatomic) NSTimeInterval lastFrameTime;

@end

// ============================================================================
// MARK: - Camera Presets
// ============================================================================

struct CameraPresets {
    // FRONT VIEW
    struct {
        math::float3 pos = math::float3{8.0f, 2.0f, 24.0f};
        math::float3 lookAt = math::float3{-0.0f, -1.5f, 0.0f};
    } front;
    // TOP VIEW
    struct {
        math::float3 pos = math::float3{0.0f, 22.0f, -18.0f};
        math::float3 lookAt = math::float3{0.0f, 0.0f, 0.0f};
    } top;
    
    // REAR VIEW
    struct {
        math::float3 pos = math::float3{8.0f, 1.0f, -16.0f};
        math::float3 lookAt = math::float3{-0.0f, 0.0f, 0.0f};
    } rear;
} cameraPresets;

// ============================================================================
// MARK: - Implementation
// ============================================================================

@implementation FilamentRenderer

// ============================================================================
// MARK: - Lifecycle
// ============================================================================

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc {
    [self cleanupFilamentResources];
}

// ============================================================================
// MARK: - Setup
// ============================================================================

- (void)setup {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        NSLog(@"[FilamentRenderer] No Metal device. Simulator/GPU issue.");
        self.backgroundColor = [UIColor blackColor];
        return;
    }
    
    [self setupMTKViewWithDevice:device];
    [self setupAppearance];
    [self scheduleFilamentSetup];
}

- (void)setupMTKViewWithDevice:(id<MTLDevice>)device {
    self.mtkView = [[MTKView alloc] initWithFrame:self.bounds device:device];
    self.mtkView.delegate = self;
    self.mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mtkView.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    self.mtkView.preferredFramesPerSecond = 60;
    self.mtkView.paused = NO;
    self.mtkView.enableSetNeedsDisplay = NO;
    self.mtkView.framebufferOnly = YES;  // Performance optimization
    
    [self addSubview:self.mtkView];
    
    // NOTE: Resolution scaling via drawableSize does NOT work with Filament!
    // Crashes in setViewport() - Filament Metal backend incompatible with manual drawableSize
    // Alternative: Use Filament Dynamic Resolution API (but 42% GPU overhead from SGSR)
    
    NSLog(@"[FilamentRenderer] MTKView created %@ (native resolution)", NSStringFromCGRect(self.mtkView.frame));
}

- (void)setupAppearance {
    self.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    self.clipsToBounds = YES;
    self.userInteractionEnabled = YES;
    self.orbitControlsEnabled = NO;
}

- (void)scheduleFilamentSetup {
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupFilament];
        
        // === PRODUCTION MODE: Auto model with optimizations ===
        [self loadModel];      // ← Auto GLB
        [self loadFloor];      // ← Floor GLB
        // [self loadDebugAxis];  // ← Not needed
        
        NSLog(@"[FilamentRenderer] 🚗 AUTO MODEL LOADED - Production optimizations active");
        NSLog(@"[FilamentRenderer] ✅ Filament setup finished");
    });
}

// ============================================================================
// MARK: - Filament Engine Setup
// ============================================================================

- (void)setupFilament {
    NSLog(@"[FilamentRenderer] setupFilament start");
    
    // Memory optimized engine configuration
    Engine::Config engineConfig;
    engineConfig.commandBufferSizeMB = 2;
    engineConfig.perRenderPassArenaSizeMB = 2;
    engineConfig.metalUploadBufferSizeBytes = 256 * 1024;
    engineConfig.resourceAllocatorCacheMaxAge = 1;
    
    self.engine = Engine::create(Engine::Backend::METAL, nullptr, nullptr, &engineConfig);
    if (!self.engine) {
        NSLog(@"[FilamentRenderer] Engine create failed");
        return;
    }
    
    [self setupSwapChain];
    [self setupRenderingComponents];
    [self setupLighting];
    
    // OPTIMIZATION: HDR enabled (will be optimized to 128×128)
    [self setupHDREnvironment];
    NSLog(@"[FilamentRenderer] ✅ HDR enabled (optimized)");
    
    [self setupCamera];
    [self setupMaterialManager];
    [self initializeAnimationState];
}

- (void)setupSwapChain {
    CAMetalLayer *metalLayer = nil;
    if ([self.mtkView.layer isKindOfClass:[CAMetalLayer class]]) {
        metalLayer = (CAMetalLayer *)self.mtkView.layer;
    }
    
    if (!metalLayer) {
        NSLog(@"[FilamentRenderer] No CAMetalLayer");
        return;
    }
    
    metalLayer.opaque = YES;
    self.swapChain = self.engine->createSwapChain((__bridge void*)metalLayer);
    
    if (!self.swapChain) {
        NSLog(@"[FilamentRenderer] swapChain create failed");
        return;
    }
}

- (void)setupRenderingComponents {
    self.renderer = self.engine->createRenderer();
    self.scene = self.engine->createScene();
    
    // Skybox
    sRGBColorA srgbaWhite = {1.0f, 1.0f, 1.0f, 1.0f};
    LinearColorA linearWhite = Color::toLinear<ACCURATE>(srgbaWhite);
    
    self.skybox = Skybox::Builder()
        .color({linearWhite.r, linearWhite.g, linearWhite.b, linearWhite.a})
        .build(*self.engine);
    
    self.scene->setSkybox(self.skybox);
    
    // View
    self.view = self.engine->createView();
    self.view->setScene(self.scene);
    self.view->setBlendMode(View::BlendMode::OPAQUE);
    
    // =========================================================================
    // PRODUCTION MODE: Optimized rendering settings
    // =========================================================================
    
    // 1. Anti-aliasing: FXAA (smooth edges without MSAA overhead)
    self.view->setAntiAliasing(View::AntiAliasing::FXAA);
    NSLog(@"[FilamentRenderer] ✅ Anti-aliasing: FXAA (saves ~280MB vs MSAA 4×)");
    
    // 2. Dynamic resolution: ENABLED (Apple SGSR for memory optimization)
    View::DynamicResolutionOptions dr;
    dr.enabled = true;
    dr.homogeneousScaling = true;
    dr.minScale = 0.5f;        // Half resolution (DEFAULT: 539 MB, 70% visual quality)
    dr.maxScale = 0.5f;        // 590×1278 = 25% pixels, balanced performance
    dr.quality = View::QualityLevel::MEDIUM;
    self.view->setDynamicResolutionOptions(dr);
    NSLog(@"[FilamentRenderer] 🎯 Dynamic Resolution ENABLED: %.0f%% resolution (%.0f%% pixels, Apple SGSR upscale)", 
          dr.minScale * 100.0f, dr.minScale * dr.minScale * 100.0f);
    
    // 3. Shadows: ENABLED (essential for realism)
    self.view->setShadowingEnabled(true);
    self.view->setShadowType(View::ShadowType::PCF);  // Soft shadows
    NSLog(@"[FilamentRenderer] ✅ Shadows: Enabled (PCF, essential for car realism)");
    
    // 4. Post-processing: Minimal (color grading only)
    self.view->setPostProcessingEnabled(true);
    self.view->setBloomOptions({.enabled = false});  // Disable bloom
    self.view->setDepthOfFieldOptions({.enabled = false});  // Disable DOF
    NSLog(@"[FilamentRenderer] ✅ Post-processing: Color grading only");
    
    // 5. Render quality: MEDIUM (good balance)
    View::RenderQuality quality;
    quality.hdrColorBuffer = View::QualityLevel::MEDIUM;
    self.view->setRenderQuality(quality);
    
    NSLog(@"[FilamentRenderer] 🚀 PRODUCTION MODE: FXAA + Shadows + HDR for premium quality");
    
    // Color grading
    LinearToneMapper linearToneMapper;
    self.colorGrading = ColorGrading::Builder()
        .toneMapper(&linearToneMapper)
        .build(*self.engine);
    
    self.view->setColorGrading(self.colorGrading);
    
    // Clear options
    Renderer::ClearOptions options;
    options.clearColor = {1.0f, 1.0f, 1.0f, 1.0f};
    options.clear = true;
    self.renderer->setClearOptions(options);
}

- (void)setupLighting {
    // =========================================================================
    // SUN LIGHT - Direkcionalno svjetlo (sjene)
    // =========================================================================
    // Ovdje podešavaš INTENZITET i SMJER sjena
    utils::Entity lightEntity = EntityManager::get().create();
    LightManager::Builder(LightManager::Type::SUN)
        .color(Color::toLinear<ACCURATE>(sRGBColor(0.98f, 0.92f, 0.89f)))  // Boja svjetla
        .intensity(SUN_LIGHT_INTENSITY)  // ← INTENZITET (mijenjaj konstantu gore)
        .direction({ SUN_LIGHT_DIRECTION_X, SUN_LIGHT_DIRECTION_Y, SUN_LIGHT_DIRECTION_Z })  // ← SMJER
        .castShadows(SHADOWS_ENABLED)    // ← ON/OFF sjena (mijenjaj konstantu gore)
        .build(*self.engine, lightEntity);
    self.scene->addEntity(lightEntity);
    
    NSLog(@"[FilamentRenderer] ☀️ Sun light: intensity=%.0f, shadows=%s, direction=(%.1f, %.1f, %.1f)",
          SUN_LIGHT_INTENSITY,
          SHADOWS_ENABLED ? "ON" : "OFF",
          SUN_LIGHT_DIRECTION_X, SUN_LIGHT_DIRECTION_Y, SUN_LIGHT_DIRECTION_Z);
    
    // Indirect light (ambient)
    math::float3 shCoefficients[1];
    shCoefficients[0] = math::float3{0.5f, 0.5f, 0.5f};
    
    self.indirectLight = IndirectLight::Builder()
        .irradiance(1, shCoefficients)
        .build(*self.engine);
    
    if (self.indirectLight) {
        self.indirectLight->setIntensity(0.15f);
        self.scene->setIndirectLight(self.indirectLight);
    }
}

- (void)setupCamera {
    NSLog(@"[FilamentRenderer] setupCamera: view=%p, engine=%p", self.view, self.engine);
    
    if (!self.view) {
        NSLog(@"[FilamentRenderer] ❌ ERROR: View is nullptr!");
        return;
    }
    
    if (!self.engine) {
        NSLog(@"[FilamentRenderer] ❌ ERROR: Engine is nullptr!");
        return;
    }
    
    utils::Entity cameraEntity = EntityManager::get().create();
    self.camera = self.engine->createCamera(cameraEntity);
    
    NSLog(@"[FilamentRenderer] Camera created, setting to view...");
    self.view->setCamera(self.camera);
    
    // Viewport - Use full drawable size (already scaled at MTKView level)
    CGSize drawableSize = self.mtkView.drawableSize;
    if (drawableSize.width == 0 || drawableSize.height == 0) {
        drawableSize = self.mtkView.bounds.size;
    }
    
    NSLog(@"[FilamentRenderer] Setting viewport %dx%d...", (int)drawableSize.width, (int)drawableSize.height);
    
    // Viewport matches drawable size (MTKView already handles scaling)
    Viewport viewport(0, 0, (uint32_t)drawableSize.width, (uint32_t)drawableSize.height);
    self.view->setViewport(viewport);
    
    NSLog(@"[FilamentRenderer] ✅ Viewport set successfully");
    
    float aspect = drawableSize.width / drawableSize.height;
    float verticalFOV = calculateVerticalFOV(FOCAL_LENGTH_MM, SENSOR_HEIGHT_MM);
    self.camera->setProjection(verticalFOV, aspect, 0.1, 1000.0, Camera::Fov::VERTICAL);
    
    NSLog(@"[FilamentRenderer] Camera: focal=%dmm, sensor=%dmm, vFOV=%.2f°, aspect=%.4f", 
          (int)FOCAL_LENGTH_MM, (int)SENSOR_HEIGHT_MM, verticalFOV, aspect);
    
    // Initialize Core3D CameraController
    if (self.cameraController) {
        delete self.cameraController;
    }
    self.cameraController = new core3d::CameraController();
    
    // Configure camera
    core3d::CameraConfig cameraConfig;
    cameraConfig.focalLengthMM = FOCAL_LENGTH_MM;
    cameraConfig.sensorHeightMM = SENSOR_HEIGHT_MM;
    cameraConfig.aspectRatio = aspect;
    self.cameraController->setConfig(cameraConfig);
    
    // Configure orbit
    core3d::OrbitConfig orbitConfig;
    orbitConfig.minDistance = MIN_DISTANCE;
    orbitConfig.maxDistance = MAX_DISTANCE;
    orbitConfig.target = core3d::Vector3(orbitTarget.x, orbitTarget.y, orbitTarget.z);
    self.cameraController->setOrbitConfig(orbitConfig);
    
    // Register presets
    core3d::CameraPreset frontPreset(
        core3d::Vector3(cameraPresets.front.pos.x, cameraPresets.front.pos.y, cameraPresets.front.pos.z),
        core3d::Vector3(cameraPresets.front.lookAt.x, cameraPresets.front.lookAt.y, cameraPresets.front.lookAt.z)
    );
    self.cameraController->registerPreset("Front", frontPreset);
    
    core3d::CameraPreset topPreset(
        core3d::Vector3(cameraPresets.top.pos.x, cameraPresets.top.pos.y, cameraPresets.top.pos.z),
        core3d::Vector3(cameraPresets.top.lookAt.x, cameraPresets.top.lookAt.y, cameraPresets.top.lookAt.z)
    );
    self.cameraController->registerPreset("Top", topPreset);
    
    core3d::CameraPreset rearPreset(
        core3d::Vector3(cameraPresets.rear.pos.x, cameraPresets.rear.pos.y, cameraPresets.rear.pos.z),
        core3d::Vector3(cameraPresets.rear.lookAt.x, cameraPresets.rear.lookAt.y, cameraPresets.rear.lookAt.z)
    );
    self.cameraController->registerPreset("Rear", rearPreset);
    
    NSLog(@"[FilamentRenderer] ✅ Core3D CameraController initialized with 3 presets");
}

- (void)setupMaterialManager {
    // Initialize Core3D MaterialManager
    if (self.materialManager) {
        delete self.materialManager;
        self.materialManager = nullptr;
    }
    self.materialManager = new core3d::MaterialManager();
    
    // Setup default materials for common car parts
    self.materialManager->applyPreset("Body", core3d::MaterialPreset::GlossyPaint);
    self.materialManager->applyPreset("Wheels", core3d::MaterialPreset::AluminumAlloy);
    self.materialManager->applyPreset("Interior", core3d::MaterialPreset::Leather);
    self.materialManager->applyPreset("Glass", core3d::MaterialPreset::Glass);
    
    NSLog(@"[FilamentRenderer] ✅ Core3D MaterialManager initialized with %zu materials", 
          self.materialManager->getAllPartNames().size());
}

- (void)initializeAnimationState {
    // Background color interpolation
    self.targetBgRed = 1.0f;
    self.targetBgGreen = 1.0f;
    self.targetBgBlue = 1.0f;
    self.targetBgAlpha = 1.0f;
    self.currentBgRed = 1.0f;
    self.currentBgGreen = 1.0f;
    self.currentBgBlue = 1.0f;
    self.currentBgAlpha = 1.0f;
    
    [self applyBackgroundColor];
    
    // Camera animation
    self.isCameraMoving = NO;
    self.camTargetPos = math::float3{0.0f, 0.0f, 0.0f};
    self.camTargetLookAt = math::float3{0.0f, 0.0f, 0.0f};
    self.camCurrentPos = math::float3{0.0f, 0.0f, 0.0f};
    self.camCurrentLookAt = math::float3{0.0f, 0.0f, 0.0f};
    
    // Orbit controls
    self.orbitRotation = math::quatf{1.0f, 0.0f, 0.0f, 0.0f};
    self.currentOrbitDistance = 20.0f;
    
    // Debug axis - initially hidden
    self.debugAxisVisible = NO;
    self.debugAxisAsset = nullptr;
    
    // Floor asset
    self.floorAsset = nullptr;
    
    // Animator
    self.animator = nullptr;
    
    // Current resolution scale (default: Half)
    self.currentResolutionScale = 0.5f;
    
    // Animation playback state
    self.isAnimationPlaying = NO;
    self.currentAnimationIndex = -1;
    self.animationElapsedTime = 0.0f;
    self.currentAnimationDuration = 0.0f;
    self.lastFrameTime = 0.0;
}

// ============================================================================
// MARK: - Asset Loading
// ============================================================================

- (void)loadModel {
    // BEST: auto_basis_etc1s.glb (mesh + texture compression, 88% smaller!)
    NSString *path = [[NSBundle mainBundle] pathForResource:@"auto_basis_etc1s" ofType:@"glb"];
    if (!path) {
        NSLog(@"[FilamentRenderer] auto_basis_etc1s.glb not found, fallback to auto_meshopt");
        path = [[NSBundle mainBundle] pathForResource:@"auto_meshopt" ofType:@"glb"];
    }
    if (!path) {
        NSLog(@"[FilamentRenderer] auto_meshopt.glb not found, fallback to auto_clean");
        path = [[NSBundle mainBundle] pathForResource:@"auto_clean" ofType:@"glb"];
    }
    if (!path) {
        NSLog(@"[FilamentRenderer] auto_clean.glb not found, fallback to original");
        path = [[NSBundle mainBundle] pathForResource:@"auto" ofType:@"glb"];
    }
    
    if (!path) {
        NSLog(@"[FilamentRenderer] No car model found in bundle");
        return;
    }
    
    NSLog(@"[FilamentRenderer] 🚗 Loading: %@ (KTX2/BasisU optimized, 88%% smaller)", [path lastPathComponent]);
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data || data.length == 0) {
        NSLog(@"[FilamentRenderer] Model file empty");
        return;
    }
    
    [self setupAssetLoading];
    [self loadAssetFromData:data];
}

- (void)setupAssetLoading {
    self.materialProvider = gltfio::createUbershaderProvider(self.engine, UBERARCHIVE_DEFAULT_DATA, UBERARCHIVE_DEFAULT_SIZE);
    if (!self.materialProvider) {
        NSLog(@"[FilamentRenderer] materialProvider create failed");
        return;
    }
    
    gltfio::AssetConfiguration config;
    config.engine = self.engine;
    config.materials = self.materialProvider;
    self.assetLoader = gltfio::AssetLoader::create(config);
    
    if (!self.assetLoader) {
        NSLog(@"[FilamentRenderer] assetLoader create failed");
        return;
    }
}

- (void)loadAssetFromData:(NSData *)data {
    self.asset = self.assetLoader->createAsset((const uint8_t*)data.bytes, (uint32_t)data.length);
    if (!self.asset) {
        NSLog(@"[FilamentRenderer] asset create failed");
        return;
    }
    
    [self setupResourceLoader];
    [self loadAssetResources];
    [self addAssetToScene];
}

- (void)setupResourceLoader {
    gltfio::ResourceConfiguration resConfig;
    resConfig.engine = self.engine;
    resConfig.gltfPath = ".";
    resConfig.normalizeSkinningWeights = true;
    // Note: generateMipmaps is controlled at TextureProvider level, not ResourceConfiguration
    self.resourceLoader = new gltfio::ResourceLoader(resConfig);
    
    // TextureProvider with mipmap generation disabled
    self.textureProvider = gltfio::createStbProvider(self.engine);
    if (self.textureProvider) {
        self.resourceLoader->addTextureProvider("image/png", self.textureProvider);
        self.resourceLoader->addTextureProvider("image/jpeg", self.textureProvider);
    }
}

- (void)loadAssetResources {
    bool resourcesLoaded = self.resourceLoader->loadResources(self.asset);
    if (!resourcesLoaded) {
        NSLog(@"[FilamentRenderer] loadResources failed");
        return;
    }
}

- (void)addAssetToScene {
    size_t entityCount = self.asset->getEntityCount();
    if (entityCount > 0) {
        const utils::Entity* entities = self.asset->getEntities();
        self.scene->addEntities(entities, entityCount);
        
        // =====================================================================
        // CAR SHADOW CONFIGURATION - Konfiguracija sjena za auto
        // =====================================================================
        // Auto BACA sjene na pod
        RenderableManager& renderableManager = self.engine->getRenderableManager();
        int shadowsConfigured = 0;
        for (size_t i = 0; i < entityCount; i++) {
            utils::Entity entity = entities[i];
            if (renderableManager.hasComponent(entity)) {
                auto instance = renderableManager.getInstance(entity);
                if (instance.isValid()) {
                    renderableManager.setCastShadows(instance, true);   // Auto BACA sjene
                    renderableManager.setReceiveShadows(instance, true); // Auto također PRIMA sjene (od drugih objekata)
                    shadowsConfigured++;
                }
            }
        }
        
        Aabb boundingBox = self.asset->getBoundingBox();
        orbitTarget = boundingBox.center();
        
        [self setupInitialCameraPosition];
        
        NSLog(@"[FilamentRenderer] 🚗 Car loaded: %zu entities (%d shadows configured)", entityCount, shadowsConfigured);
        
        // =====================================================================
        // DETECT AND LOG ANIMATIONS - Detektiraj i ispiši sve animacije
        // =====================================================================
        [self detectAndLogAnimations];
    }
}

// ============================================================================
// MARK: - Entity Inspection
// ============================================================================

- (void)logAllEntities {
    if (!self.asset) {
        NSLog(@"[FilamentRenderer] ⚠️ No asset loaded for entity inspection");
        return;
    }
    
    size_t entityCount = self.asset->getEntityCount();
    const utils::Entity* entities = self.asset->getEntities();
    
    NSLog(@"[FilamentRenderer] 📦 ============================================");
    NSLog(@"[FilamentRenderer] 📦 CAR ENTITIES: %zu", entityCount);
    NSLog(@"[FilamentRenderer] 📦 ============================================");
    
    RenderableManager& renderableManager = self.engine->getRenderableManager();
    TransformManager& transformManager = self.engine->getTransformManager();
    
    for (size_t i = 0; i < entityCount; i++) {
        utils::Entity entity = entities[i];
        
        // Get entity name from asset
        const char* name = self.asset->getName(entity);
        NSString *entityName = name ? [NSString stringWithUTF8String:name] : @"(unnamed)";
        
        // Check if entity has renderable component
        bool hasRenderable = renderableManager.hasComponent(entity);
        bool hasTransform = transformManager.hasComponent(entity);
        
        NSLog(@"[FilamentRenderer] 📦 Entity #%zu:", i);
        NSLog(@"[FilamentRenderer]    Name: %@", entityName);
        NSLog(@"[FilamentRenderer]    Renderable: %s", hasRenderable ? "YES" : "NO");
        NSLog(@"[FilamentRenderer]    Transform: %s", hasTransform ? "YES" : "NO");
        
        if (hasTransform) {
            auto instance = transformManager.getInstance(entity);
            if (instance.isValid()) {
                math::mat4f transform = transformManager.getTransform(instance);
                math::float3 translation = transform[3].xyz;
                NSLog(@"[FilamentRenderer]    Position: (%.2f, %.2f, %.2f)", 
                      translation.x, translation.y, translation.z);
            }
        }
        
        NSLog(@"[FilamentRenderer]    ----------------------------------------");
    }
    
    NSLog(@"[FilamentRenderer] 📦 ============================================");
}

// ============================================================================
// MARK: - Animation Detection
// ============================================================================

- (void)detectAndLogAnimations {
    if (!self.asset) {
        NSLog(@"[FilamentRenderer] ⚠️ No asset loaded for animation detection");
        return;
    }
    
    // Get animator from asset and store it
    self.animator = self.asset->getInstance()->getAnimator();
    if (!self.animator) {
        NSLog(@"[FilamentRenderer] ℹ️ Car model has NO animator (no instance or no animations)");
        return;
    }
    
    // Create Core3D AnimationController wrapper
    if (self.animationController) {
        delete self.animationController;
    }
    self.animationController = new core3d::AnimationController(self.animator);
    NSLog(@"[FilamentRenderer] ✅ Core3D AnimationController initialized");
    
    size_t animationCount = self.animator->getAnimationCount();
    NSLog(@"[FilamentRenderer] 🎬 ============================================");
    NSLog(@"[FilamentRenderer] 🎬 CAR ANIMATIONS DETECTED: %zu", animationCount);
    NSLog(@"[FilamentRenderer] 🎬 ============================================");
    
    if (animationCount == 0) {
        NSLog(@"[FilamentRenderer] ℹ️ No animations found in car model");
        return;
    }
    
    for (size_t i = 0; i < animationCount; i++) {
        const char* animName = self.animator->getAnimationName(i);
        float duration = self.animator->getAnimationDuration(i);
        
        NSLog(@"[FilamentRenderer] 🎬 Animation #%zu:", i);
        NSLog(@"[FilamentRenderer]    Name: %s", animName ? animName : "(unnamed)");
        NSLog(@"[FilamentRenderer]    Duration: %.2f seconds", duration);
        NSLog(@"[FilamentRenderer]    ----------------------------------------");
    }
    
    NSLog(@"[FilamentRenderer] 🎬 ============================================");
}

// ============================================================================
// MARK: - Animation Playback
// ============================================================================

- (NSInteger)getAnimationCount {
    if (!self.animator) return 0;
    return (NSInteger)self.animator->getAnimationCount();
}

- (NSString *)getAnimationNameAtIndex:(NSInteger)index {
    if (!self.animator || index < 0 || index >= [self getAnimationCount]) {
        return nil;
    }
    
    const char* name = self.animator->getAnimationName((size_t)index);
    return name ? [NSString stringWithUTF8String:name] : [NSString stringWithFormat:@"Animation %ld", (long)index];
}

- (void)playAnimationAtIndex:(NSInteger)index {
    if (!self.animationController || index < 0 || index >= [self getAnimationCount]) {
        NSLog(@"[FilamentRenderer] ❌ Invalid animation index: %ld", (long)index);
        return;
    }
    
    // Use Core3D AnimationController to play
    self.animationController->play((size_t)index, false);  // No looping
    
    NSString *animName = [self getAnimationNameAtIndex:index];
    float duration = self.animationController->getDuration();
    
    // Update lastFrameTime for iOS time tracking
    self.lastFrameTime = CACurrentMediaTime();
    
    NSLog(@"[FilamentRenderer] ▶️ STARTED animation: %@ (duration: %.2fs) [Core3D]", animName, duration);
}

- (void)stopAnimation {
    if (!self.animationController || !self.animationController->isPlaying()) return;
    
    NSString *animName = [self getAnimationNameAtIndex:self.animationController->getCurrentIndex()];
    NSLog(@"[FilamentRenderer] ⏹️ STOPPED animation: %@ (at %.2fs / %.2fs) [Core3D]", 
          animName, self.animationController->getElapsedTime(), self.animationController->getDuration());
    
    self.animationController->stop();
}

- (void)updateAnimation {
    if (!self.animationController || !self.animationController->isPlaying()) return;
    
    // iOS: Calculate delta time using CACurrentMediaTime
    NSTimeInterval currentTime = CACurrentMediaTime();
    float deltaTime = (float)(currentTime - self.lastFrameTime);
    self.lastFrameTime = currentTime;
    
    // Track if was playing before update
    bool wasPlaying = self.animationController->isPlaying();
    
    // Core3D: Update animation (handles timing, looping, bone matrices)
    self.animationController->update(deltaTime);
    
    // Check if animation just finished
    if (wasPlaying && !self.animationController->isPlaying()) {
        NSString *animName = [self getAnimationNameAtIndex:self.animationController->getCurrentIndex()];
        NSLog(@"[FilamentRenderer] ✅ FINISHED animation: %@ (duration: %.2fs) [Core3D]", 
              animName, self.animationController->getDuration());
    }
}

- (void)setupInitialCameraPosition {
    if (!self.cameraController || !self.camera) return;
    
    // Use Core3D to set initial Front preset (no smooth transition)
    self.cameraController->moveToPreset("Front", false);
    
    // Get the state and apply to Filament camera immediately
    const core3d::CameraState& state = self.cameraController->getState();
    math::float3 pos(state.position.x, state.position.y, state.position.z);
    math::float3 lookAt(state.lookAt.x, state.lookAt.y, state.lookAt.z);
    math::float3 up(state.upVector.x, state.upVector.y, state.upVector.z);
    
    self.camera->lookAt(pos, lookAt, up);
    
    NSLog(@"[FilamentRenderer] 📷 Initial camera position set to Front [Core3D]");
}

- (void)loadDebugAxis {
    float offsetX = 0.0f;
    float offsetY = 0.0f;
    float offsetZ = 0.0f;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"axis_debug" ofType:@"glb"];
    if (!path) return;
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data || data.length == 0) return;
    
    if (!self.assetLoader || !self.resourceLoader) return;
    
    gltfio::FilamentAsset *debugAsset = self.assetLoader->createAsset((const uint8_t*)data.bytes, (uint32_t)data.length);
    if (!debugAsset) return;
    
    bool resourcesLoaded = self.resourceLoader->loadResources(debugAsset);
    if (!resourcesLoaded) {
        self.assetLoader->destroyAsset(debugAsset);
        return;
    }
    
    // Store the debug axis asset
    self.debugAxisAsset = debugAsset;
    
    size_t entityCount = debugAsset->getEntityCount();
    if (entityCount > 0) {
        const utils::Entity* entities = debugAsset->getEntities();
        
        TransformManager& transformManager = self.engine->getTransformManager();
        math::float3 offset = math::float3{offsetX, offsetY, offsetZ};
        
        // Add entities to scene
        self.scene->addEntities(entities, entityCount);
        
        for (size_t i = 0; i < entityCount; i++) {
            utils::Entity entity = entities[i];
            if (transformManager.hasComponent(entity)) {
                auto instance = transformManager.getInstance(entity);
                if (!instance.isValid()) continue;
                
                math::mat4f currentTransform = transformManager.getTransform(instance);
                math::mat4f translationMatrix = math::mat4f::translation(offset);
                math::mat4f offsetTransform = translationMatrix * currentTransform;
                transformManager.setTransform(instance, offsetTransform);
            }
        }
        
        // Initially hide the debug axis (remove from scene)
        self.scene->removeEntities(entities, entityCount);
        self.debugAxisVisible = NO;
        
        NSLog(@"[FilamentRenderer] Debug axis loaded and hidden (initial state: OFF)");
    }
}

- (void)loadFloor {
    // SM_Floor.glb je u root bundle-a
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SM_Floor" ofType:@"glb"];
    if (!path) {
        NSLog(@"[FilamentRenderer] ❌ SM_Floor.glb not found in bundle");
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data || data.length == 0) {
        NSLog(@"[FilamentRenderer] ❌ SM_Floor.glb empty, size: %lu", (unsigned long)data.length);
        return;
    }
    
    if (!self.assetLoader || !self.resourceLoader) {
        NSLog(@"[FilamentRenderer] ❌ Asset loader not ready for floor");
        return;
    }
    
    gltfio::FilamentAsset *floorAsset = self.assetLoader->createAsset((const uint8_t*)data.bytes, (uint32_t)data.length);
    if (!floorAsset) {
        NSLog(@"[FilamentRenderer] ❌ Floor asset creation failed");
        return;
    }
    
    bool resourcesLoaded = self.resourceLoader->loadResources(floorAsset);
    if (!resourcesLoaded) {
        NSLog(@"[FilamentRenderer] ❌ Floor resources loading failed");
        self.assetLoader->destroyAsset(floorAsset);
        return;
    }
    
    self.floorAsset = floorAsset;
    
    size_t entityCount = floorAsset->getEntityCount();
    if (entityCount > 0) {
        const utils::Entity* entities = floorAsset->getEntities();
        
        // Add floor to scene
        self.scene->addEntities(entities, entityCount);
        
        // Configure shadows: floor receives shadows but doesn't cast them
        RenderableManager& renderableManager = self.engine->getRenderableManager();
        for (size_t i = 0; i < entityCount; i++) {
            utils::Entity entity = entities[i];
            if (renderableManager.hasComponent(entity)) {
                auto instance = renderableManager.getInstance(entity);
                if (instance.isValid()) {
                    renderableManager.setCastShadows(instance, false);   // Ne baca sjene
                    renderableManager.setReceiveShadows(instance, true);  // Prima sjene
                }
            }
        }
        
        NSLog(@"[FilamentRenderer] ✅ Floor loaded: %zu entities, shadows enabled", entityCount);
    }
}

// ============================================================================
// MARK: - Camera Controls
// ============================================================================

- (void)moveToPresetFront {
    if (!self.cameraController) return;
    
    NSTimeInterval startTime = CACurrentMediaTime();
    
    // Use Core3D CameraController
    self.cameraController->moveToPreset("Front", true);
    
    NSTimeInterval elapsed = (CACurrentMediaTime() - startTime) * 1000.0;
    NSLog(@"[FilamentRenderer] 📷 Front preset triggered in %.1fms [Core3D]", elapsed);
}

- (void)moveToPresetTop {
    if (!self.cameraController) return;
    
    NSTimeInterval startTime = CACurrentMediaTime();
    
    // Use Core3D CameraController
    self.cameraController->moveToPreset("Top", true);
    
    NSTimeInterval elapsed = (CACurrentMediaTime() - startTime) * 1000.0;
    NSLog(@"[FilamentRenderer] 📷 Top preset triggered in %.1fms [Core3D]", elapsed);
}

- (void)moveToPresetRear {
    if (!self.cameraController) return;
    
    NSTimeInterval startTime = CACurrentMediaTime();
    
    // Use Core3D CameraController
    self.cameraController->moveToPreset("Rear", true);
    
    NSTimeInterval elapsed = (CACurrentMediaTime() - startTime) * 1000.0;
    NSLog(@"[FilamentRenderer] 📷 Rear preset triggered in %.1fms [Core3D]", elapsed);
}

- (void)setPreset:(const char *)presetName position:(CameraPreset)preset {
    if (strcmp(presetName, "front") == 0) {
        cameraPresets.front.pos = math::float3{preset.posX, preset.posY, preset.posZ};
        cameraPresets.front.lookAt = math::float3{preset.targetX, preset.targetY, preset.targetZ};
    } else if (strcmp(presetName, "top") == 0) {
        cameraPresets.top.pos = math::float3{preset.posX, preset.posY, preset.posZ};
        cameraPresets.top.lookAt = math::float3{preset.targetX, preset.targetY, preset.targetZ};
    } else if (strcmp(presetName, "rear") == 0) {
        cameraPresets.rear.pos = math::float3{preset.posX, preset.posY, preset.posZ};
        cameraPresets.rear.lookAt = math::float3{preset.targetX, preset.targetY, preset.targetZ};
    }
}

// ============================================================================
// MARK: - Orbit Controls
// ============================================================================

- (void)setOrbitControlsEnabled:(BOOL)enabled {
    _orbitControlsEnabled = enabled;
}

- (void)updateCameraFromQuaternion {
    if (!self.camera) return;
    
    // Clamp distance
    float distance = fmaxf(MIN_DISTANCE, fminf(MAX_DISTANCE, self.currentOrbitDistance));
    
    // Default camera direction - looking along positive Z
    math::float3 defaultDirection = math::float3{0.0f, 0.0f, 1.0f};
    
    // Rotate direction vector by quaternion
    math::float3 rotatedDirection = self.orbitRotation * defaultDirection;
    
    // Calculate camera position
    math::float3 cameraPosition = orbitTarget + rotatedDirection * distance;
    
    // Calculate up vector from quaternion
    math::float3 defaultUp = math::float3{0.0f, 1.0f, 0.0f};
    math::float3 rotatedUp = self.orbitRotation * defaultUp;
    
    // Set camera
    self.camera->lookAt(cameraPosition, orbitTarget, rotatedUp);
}

- (void)initializeOrbitRotationFromCamera {
    if (!self.camera) return;
    
    // Get current camera position
    math::double3 cameraPos = self.camera->getPosition();
    math::float3 cameraPosFloat = math::float3{(float)cameraPos.x, (float)cameraPos.y, (float)cameraPos.z};
    
    // Get current camera orientation (up vector)
    math::float3 cameraUp = self.camera->getUpVector();
    
    // IMPORTANT: Use actual lookAt target from preset, not orbitTarget
    // Presets use different lookAt points (camCurrentLookAt), so we need to use actual lookAt instead of orbitTarget
    // When preset lerp finishes, camCurrentLookAt is set to camTargetLookAt, so we always use camCurrentLookAt if available
    math::float3 actualLookAtTarget = orbitTarget; // Default fallback
    if (fabsf(self.camCurrentLookAt.x) > 0.0001f || fabsf(self.camCurrentLookAt.y) > 0.0001f || fabsf(self.camCurrentLookAt.z) > 0.0001f) {
        // Use lookAt from preset (active or finished)
        actualLookAtTarget = self.camCurrentLookAt;
    }
    
    // Calculate vector from actual lookAt target to camera (camera direction looks NEGATIVE from this direction)
    math::float3 toTarget = actualLookAtTarget - cameraPosFloat;
    float distance = sqrtf(toTarget.x * toTarget.x + toTarget.y * toTarget.y + toTarget.z * toTarget.z);
    
    if (distance < 0.001f) {
        // Default quaternion (identity)
        self.orbitRotation = math::quatf{1.0f, 0.0f, 0.0f, 0.0f};
        self.currentOrbitDistance = 20.0f;
        return;
    }
    
    // Normalize direction (camera looks TOWARD target, not FROM target)
    math::float3 forwardDirection;
    forwardDirection.x = -toTarget.x / distance;
    forwardDirection.y = -toTarget.y / distance;
    forwardDirection.z = -toTarget.z / distance;
    
    // Calculate quaternion that rotates default direction and up vector to current camera orientation
    // Default: forward = (0,0,1), up = (0,1,0)
    math::float3 defaultForward = math::float3{0.0f, 0.0f, 1.0f};
    math::float3 defaultUp = math::float3{0.0f, 1.0f, 0.0f};
    
    // Use fromDirectedRotation for basic direction rotation
    math::quatf baseRotation = math::quatf::fromDirectedRotation(defaultForward, forwardDirection);
    
    // Rotate default up vector with this rotation
    math::float3 rotatedUp = baseRotation * defaultUp;
    
    // Calculate additional rotation around forward axis to align up vector
    math::float3 upAxis = forwardDirection; // Rotation around forward axis
    float upAngle = atan2f(dot(cross(rotatedUp, cameraUp), upAxis), dot(rotatedUp, cameraUp));
    math::quatf upRotation = math::quatf::fromAxisAngle(upAxis, upAngle);
    
    // Combine rotations
    self.orbitRotation = upRotation * baseRotation;
    self.currentOrbitDistance = distance;
}

// ============================================================================
// MARK: - Gesture Handling
// ============================================================================

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.orbitControlsEnabled) { return; }
    UITouch *touch = touches.anyObject;
    if (!touch || !self.camera) return;
    
    // Stop camera preset lerp if active and initialize quaternion
    // IMPORTANT: This must happen BEFORE any rotation to avoid drift
    if (self.isCameraMoving) {
        self.isCameraMoving = NO;
        // Initialize quaternion from EXACT current camera position and orientation
        [self initializeOrbitRotationFromCamera];
    }
    
    CGPoint location = [touch locationInView:self];
    CGPoint prev = [touch previousLocationInView:self];
    
    const float sensitivity = 0.003f;
    
    // Calculate movement delta
    float deltaX = (location.x - prev.x) * sensitivity;
    float deltaY = (location.y - prev.y) * sensitivity;
    
    // Rotation around Y axis (horizontal) - INVERTED
    math::quatf yRotation = math::quatf::fromAxisAngle(math::float3{0.0f, 1.0f, 0.0f}, -deltaX);
    
    // Rotation around X axis (vertical) - we need to get current X axis from quaternion first
    math::float3 currentRight = self.orbitRotation * math::float3{1.0f, 0.0f, 0.0f};
    math::quatf xRotation = math::quatf::fromAxisAngle(currentRight, -deltaY);
    
    // Combine rotations: first Y (horizontal), then X (vertical)
    self.orbitRotation = xRotation * yRotation * self.orbitRotation;
    
    // Normalize quaternion (to remain unit quaternion)
    self.orbitRotation = normalize(self.orbitRotation);
    
    // Update camera
    [self updateCameraFromQuaternion];
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture {
    if (!self.orbitControlsEnabled) { return; }
    if (gesture.state == UIGestureRecognizerStateChanged && self.camera) {
        // Stop camera preset lerp if active and initialize quaternion
        if (self.isCameraMoving) {
            self.isCameraMoving = NO;
            // Initialize quaternion from EXACT current camera position and orientation
            [self initializeOrbitRotationFromCamera];
        }
        
        // Update distance
        self.currentOrbitDistance /= gesture.scale;
        gesture.scale = 1.0;
        
        // Set camera with new distance
        [self updateCameraFromQuaternion];
    }
}

// ============================================================================
// MARK: - HDR Environment Setup
// ============================================================================

- (Texture*)loadKTXTexture:(NSString*)name inDirectory:(NSString*)directory outData:(NSData**)outData outBundle:(image::Ktx1Bundle**)outBundle {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"ktx" inDirectory:directory];
    if (!path) {
        NSLog(@"[FilamentRenderer] ❌ KTX NOT FOUND: %@.ktx in directory: %@", name, directory);
        NSLog(@"[FilamentRenderer] Bundle path: %@", [[NSBundle mainBundle] bundlePath]);
        return nullptr;
    }
    
    NSLog(@"[FilamentRenderer] ✅ KTX FOUND at: %@", path);

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data || data.length < 12) {
        NSLog(@"[FilamentRenderer] ❌ KTX data invalid, size: %lu", (unsigned long)data.length);
        return nullptr;
    }
    
    NSLog(@"[FilamentRenderer] 📦 KTX data loaded, size: %lu bytes", (unsigned long)data.length);

    @try {
        // Create a heap-allocated copy that Ktx1Bundle can own
        uint32_t dataSize = (uint32_t)data.length;
        uint8_t *dataCopy = (uint8_t*)malloc(dataSize);
        if (!dataCopy) {
            NSLog(@"[FilamentRenderer] ❌ Failed to allocate memory for KTX copy");
            return nullptr;
        }
        
        memcpy(dataCopy, data.bytes, dataSize);
        
        // Ktx1Bundle takes ownership and will free dataCopy in its destructor
        image::Ktx1Bundle *bundle = new image::Ktx1Bundle(dataCopy, dataSize);
        
        // Try with sRGB = true (third parameter)
        Texture *texture = ktxreader::Ktx1Reader::createTexture(self.engine, bundle, true);
        
        // DON'T delete bundle - keep it alive!
        // delete bundle;
        
        if (texture) {
            NSLog(@"[FilamentRenderer] ✅ KTX texture created successfully!");
            
            // Log actual texture resolution and mipmap levels
            uint32_t width = texture->getWidth(0);   // Level 0 = base resolution
            uint32_t height = texture->getHeight(0);
            uint32_t levels = texture->getLevels();
            NSLog(@"[FilamentRenderer] 📐 KTX Resolution: %u×%u (cubemap face)", width, height);
            NSLog(@"[FilamentRenderer] 📊 Mipmap levels: %u", levels);
            
            // Calculate total memory (rough estimate)
            uint32_t pixelsPerFace = width * height;
            uint32_t totalPixels = pixelsPerFace * 6;  // 6 cubemap faces
            float bytesPerPixel = 6.0f;  // RGB16F estimate
            float totalMB = (totalPixels * bytesPerPixel * 1.5f) / (1024.0f * 1024.0f);  // 1.5× for mipmaps
            NSLog(@"[FilamentRenderer] 💾 Estimated GPU memory: %.1f MB", totalMB);
            
            // Store original NSData to keep reference
            if (outData) {
                *outData = data;
            }
            // Keep bundle alive
            if (outBundle) {
                *outBundle = bundle;
            }
        } else {
            NSLog(@"[FilamentRenderer] ❌ KTX texture creation failed");
            delete bundle;  // Only delete if texture creation failed
        }
        return texture;
    } @catch (NSException *e) {
        NSLog(@"[FilamentRenderer] ❌ KTX exception: %@", e.reason);
        return nullptr;
    }
}

- (BOOL)loadSphericalHarmonicsFromDirectory:(NSString*)directory outBands:(math::float3*)outBands {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sh" ofType:@"txt" inDirectory:directory];
    if (!path) {
        NSLog(@"[FilamentRenderer] ❌ SH NOT FOUND: sh.txt in directory: %@", directory);
        return NO;
    }
    
    NSLog(@"[FilamentRenderer] ✅ SH FOUND at: %@", path);
    
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!content) {
        NSLog(@"[FilamentRenderer] ❌ SH file could not be opened: %@", error);
        return NO;
    }
    
    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // Parse format: ( r, g, b); // comment
    int parsed = 0;
    for (NSString *line in lines) {
        if (parsed >= 9) break;
        
        // Trim and extract values between parentheses
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSRange startParen = [trimmed rangeOfString:@"("];
        NSRange endParen = [trimmed rangeOfString:@")"];
        
        if (startParen.location == NSNotFound || endParen.location == NSNotFound) continue;
        
        NSRange valuesRange = NSMakeRange(startParen.location + 1, endParen.location - startParen.location - 1);
        NSString *valuesStr = [trimmed substringWithRange:valuesRange];
        NSArray *vals = [valuesStr componentsSeparatedByString:@","];
        
        if (vals.count != 3) {
            NSLog(@"[FilamentRenderer] ❌ SH invalid format at line %d", parsed);
            return NO;
        }
        
        float r = [[vals[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] floatValue];
        float g = [[vals[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] floatValue];
        float b = [[vals[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] floatValue];
        
        outBands[parsed++] = math::float3{r, g, b};
    }
    
    if (parsed != 9) {
        NSLog(@"[FilamentRenderer] ❌ SH expected 9 bands, got %d", parsed);
        return NO;
    }
    
    NSLog(@"[FilamentRenderer] ✅ SH loaded successfully (9 bands)");
    return YES;
}

- (void)setupHDREnvironment {
    NSLog(@"[FilamentRenderer] HDR Reflections ONLY – loading async...");

    // === ASYNC LOADING: Load HDR resources in background thread ===
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // === 1. Files are in root bundle (not in subdirectory) ===
        NSString *envDir = nil;
        
        // === 2. Load SH (diffuse lighting) in background ===
        math::float3 shBands[9];
        [self loadSphericalHarmonicsFromDirectory:envDir outBands:shBands];
        
        // === 3. Load IBL KTX (reflections) in background ===
        // PRODUCTION: Use 256×256 for best reflection quality (only 14MB more than 128×128)
        NSData *textureData = nil;
        image::Ktx1Bundle *bundle = nullptr;
        Texture *iblTexture = [self loadKTXTexture:@"ibl_output_ibl" inDirectory:envDir outData:&textureData outBundle:&bundle];
        
        // === HEAP ALLOCATION: Allocate shBands on heap to survive thread boundary ===
        math::float3 *shBandsHeap = new math::float3[9];
        for (int i = 0; i < 9; i++) {
            shBandsHeap[i] = shBands[i];
        }
        
        // === 4. Switch to main thread for Filament resource creation ===
        dispatch_async(dispatch_get_main_queue(), ^{
            // Destroy old resources
            if (self.indirectLight) self.engine->destroy(self.indirectLight);
            if (self.iblTexture) self.engine->destroy(self.iblTexture);
            if (self.ktxBundle) delete self.ktxBundle;
            
            // Keep texture data and bundle alive
            self.iblTextureData = textureData;
            self.ktxBundle = bundle;
            
            // === 5. Create IndirectLight with reflections + SH ===
            self.iblTexture = iblTexture;
            self.indirectLight = IndirectLight::Builder()
                .reflections(self.iblTexture)     // ← REFLECTIONS
                .irradiance(3, shBandsHeap)       // ← Diffuse (colors) - heap allocated!
                .intensity(45000.0f)              // ← HDR intensity
                .build(*self.engine);
            
            self.scene->setIndirectLight(self.indirectLight);
            
            // Clean up heap allocation
            delete[] shBandsHeap;
            
            NSLog(@"[FilamentRenderer] ✅ HDR loaded async – reflections active!");
        });
    });
}

// ============================================================================
// MARK: - Background & Environment
// ============================================================================

- (void)setBackgroundColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
    red = fmaxf(0.0f, fminf(1.0f, red));
    green = fmaxf(0.0f, fminf(1.0f, green));
    blue = fmaxf(0.0f, fminf(1.0f, blue));
    alpha = fmaxf(0.0f, fminf(1.0f, alpha));
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setBackgroundColorRed:red green:green blue:blue alpha:alpha];
        });
        return;
    }
    
    self.targetBgRed = red;
    self.targetBgGreen = green;
    self.targetBgBlue = blue;
    self.targetBgAlpha = alpha;
    
    if (self.currentBgRed == 0.0f && self.currentBgGreen == 0.0f &&
        self.currentBgBlue == 0.0f && self.currentBgAlpha == 0.0f) {
        self.currentBgRed = red;
        self.currentBgGreen = green;
        self.currentBgBlue = blue;
        self.currentBgAlpha = alpha;
        [self applyBackgroundColor];
    }
}

- (void)applyBackgroundColor {
    float red = self.currentBgRed;
    float green = self.currentBgGreen;
    float blue = self.currentBgBlue;
    float alpha = self.currentBgAlpha;
    
    sRGBColorA srgbaColor = {red, green, blue, alpha};
    LinearColorA linearColor = Color::toLinear<ACCURATE>(srgbaColor);
    
    if (self.skybox) {
        self.skybox->setColor({linearColor.r, linearColor.g, linearColor.b, linearColor.a});
    }
    
    if (self.renderer) {
        Renderer::ClearOptions options;
        options.clearColor = {linearColor.r, linearColor.g, linearColor.b, linearColor.a};
        options.clear = true;
        self.renderer->setClearOptions(options);
    }
    
    // Don't touch MTKView during frame rendering - causes drawable conflicts
    self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

// ============================================================================
// MARK: - Debug Axis Toggle
// ============================================================================

- (void)toggleDebugAxis {
    if (!self.debugAxisAsset || !self.scene) return;
    
    size_t entityCount = self.debugAxisAsset->getEntityCount();
    if (entityCount == 0) return;
    
    const utils::Entity* entities = self.debugAxisAsset->getEntities();
    
    if (self.debugAxisVisible) {
        // Hide: remove from scene
        self.scene->removeEntities(entities, entityCount);
        self.debugAxisVisible = NO;
        NSLog(@"[FilamentRenderer] Debug axis hidden");
    } else {
        // Show: add to scene
        self.scene->addEntities(entities, entityCount);
        self.debugAxisVisible = YES;
        NSLog(@"[FilamentRenderer] Debug axis visible");
    }
}

- (BOOL)isDebugAxisVisible {
    return self.debugAxisVisible;
}

// ============================================================================
// MARK: - Rendering Loop
// ============================================================================

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    Viewport viewport(0, 0, (uint32_t)size.width, (uint32_t)size.height);
    self.view->setViewport(viewport);
    
    float aspect = size.width / size.height;
    float verticalFOV = calculateVerticalFOV(FOCAL_LENGTH_MM, SENSOR_HEIGHT_MM);
    self.camera->setProjection(verticalFOV, aspect, 0.1, 1000.0, Camera::Fov::VERTICAL);
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    const float lerpSpeed = 0.08f;
    const float deltaTime = 1.0f / 60.0f;  // Assuming 60fps
    
    [self updateBackgroundColorInterpolationWithSpeed:lerpSpeed];
    [self updateCameraFromCore3D:deltaTime];  // Core3D camera update
    [self updateAnimation];  // Core3D animation update
    [self renderFrame];
}

- (void)updateBackgroundColorInterpolationWithSpeed:(float)speed {
    float dr = self.targetBgRed - self.currentBgRed;
    float dg = self.targetBgGreen - self.currentBgGreen;
    float db = self.targetBgBlue - self.currentBgBlue;
    float da = self.targetBgAlpha - self.currentBgAlpha;
    
    if (fabsf(dr) > 0.001f || fabsf(dg) > 0.001f || fabsf(db) > 0.001f || fabsf(da) > 0.001f) {
        self.currentBgRed += dr * speed;
        self.currentBgGreen += dg * speed;
        self.currentBgBlue += db * speed;
        self.currentBgAlpha += da * speed;
        
        [self applyBackgroundColor];
    }
}

- (void)updateCameraFromCore3D:(float)deltaTime {
    if (!self.cameraController || !self.camera) return;
    
    // Update Core3D camera controller (only if moving)
    if (self.cameraController->isMoving()) {
        self.cameraController->update(deltaTime);
        
        // Get updated camera state from Core3D
        const core3d::CameraState& state = self.cameraController->getState();
        
        // Apply to Filament camera
        math::float3 pos(state.position.x, state.position.y, state.position.z);
        math::float3 lookAt(state.lookAt.x, state.lookAt.y, state.lookAt.z);
        math::float3 up(state.upVector.x, state.upVector.y, state.upVector.z);
        
        self.camera->lookAt(pos, lookAt, up);
    }
}

- (void)updateCameraAnimationWithSpeed:(float)speed {
    if (self.isCameraMoving && self.camera) {
        // Lerp camera position
        math::float3 posDiff = self.camTargetPos - self.camCurrentPos;
        math::float3 lookAtDiff = self.camTargetLookAt - self.camCurrentLookAt;
        
        self.camCurrentPos = self.camCurrentPos + posDiff * speed;
        self.camCurrentLookAt = self.camCurrentLookAt + lookAtDiff * speed;
        
        // Set camera - use current lerp position
        math::float3 up = math::float3{0.0f, 1.0f, 0.0f};
        self.camera->lookAt(self.camCurrentPos, self.camCurrentLookAt, up);
        
        // Check if close enough to target
        float distance = sqrtf(posDiff.x * posDiff.x + posDiff.y * posDiff.y + posDiff.z * posDiff.z);
        if (distance < 0.01f) {
            // Set exactly to target
            self.camera->lookAt(self.camTargetPos, self.camTargetLookAt, up);
            self.camCurrentPos = self.camTargetPos;
            self.camCurrentLookAt = self.camTargetLookAt;
            self.isCameraMoving = NO;
            
            // Update orbit distance for pinch gesture
            math::float3 dir = self.camTargetPos - self.camTargetLookAt;
            self.currentOrbitDistance = sqrtf(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z);
            
            // IMPORTANT: Initialize quaternion ONLY when lerp finishes - from EXACT final position
            // camCurrentLookAt is set to camTargetLookAt, so initializeOrbitRotationFromCamera
            // uses actual lookAt target from preset instead of orbitTarget
            [self initializeOrbitRotationFromCamera];
        }
        // NOTE: Quaternion is NOT initialized during lerp, only at the end, to avoid drift
        // Orbit controls now use quaternions - no gimbal lock issues!
    }
}

- (void)renderFrame {
    if (self.renderer && self.swapChain && self.view) {
        if (self.renderer->beginFrame(self.swapChain)) {
            self.renderer->render(self.view);
            self.renderer->endFrame();
        }
    }
}

// ============================================================================
// MARK: - Cleanup
// ============================================================================

- (void)cleanupFilamentResources {
    // Core3D cleanup - FIRST before any Filament resources
    if (self.animationController) {
        delete self.animationController;
        self.animationController = nullptr;
        NSLog(@"[FilamentRenderer] 🗑️ Core3D AnimationController deleted");
    }
    
    if (self.cameraController) {
        delete self.cameraController;
        self.cameraController = nullptr;
        NSLog(@"[FilamentRenderer] 🗑️ Core3D CameraController deleted");
    }
    
    if (self.materialManager) {
        delete self.materialManager;
        self.materialManager = nullptr;
        NSLog(@"[FilamentRenderer] 🗑️ Core3D MaterialManager deleted");
    }
    
    gltfio::FilamentAsset *asset = self.asset;
    gltfio::AssetLoader *assetLoader = self.assetLoader;
    gltfio::ResourceLoader *resourceLoader = self.resourceLoader;
    gltfio::MaterialProvider *materialProvider = self.materialProvider;
    Engine *engine = self.engine;
    Camera *camera = self.camera;
    View *view = self.view;
    Scene *scene = self.scene;
    Renderer *renderer = self.renderer;
    SwapChain *swapChain = self.swapChain;
    Skybox *skybox = self.skybox;
    
    // Remove asset entities from scene BEFORE destroying asset
    if (asset && scene) {
        size_t entityCount = asset->getEntityCount();
        if (entityCount > 0) {
            scene->removeEntities(asset->getEntities(), entityCount);
        }
    }
    
    // Remove debug axis entities from scene BEFORE destroying asset
    if (self.debugAxisAsset && scene) {
        size_t debugEntityCount = self.debugAxisAsset->getEntityCount();
        if (debugEntityCount > 0) {
            scene->removeEntities(self.debugAxisAsset->getEntities(), debugEntityCount);
        }
    }
    
    // Remove floor entities from scene BEFORE destroying asset
    if (self.floorAsset && scene) {
        size_t floorEntityCount = self.floorAsset->getEntityCount();
        if (floorEntityCount > 0) {
            scene->removeEntities(self.floorAsset->getEntities(), floorEntityCount);
        }
    }
    
    if (asset && assetLoader) {
        assetLoader->destroyAsset(asset);
        self.asset = nullptr;
    }
    
    if (self.debugAxisAsset && assetLoader) {
        assetLoader->destroyAsset(self.debugAxisAsset);
        self.debugAxisAsset = nullptr;
    }
    
    if (self.floorAsset && assetLoader) {
        assetLoader->destroyAsset(self.floorAsset);
        self.floorAsset = nullptr;
    }
    
    if (resourceLoader) {
        delete resourceLoader;
        self.resourceLoader = nullptr;
    }
    
    if (self.textureProvider) {
        delete self.textureProvider;
        self.textureProvider = nullptr;
    }
    
    if (materialProvider) {
        // Don't call destroyMaterials() - Engine handles this automatically
        delete materialProvider;
        self.materialProvider = nullptr;
    }
    
    if (assetLoader) {
        gltfio::AssetLoader::destroy(&assetLoader);
        self.assetLoader = nullptr;
    }
    
    if (engine) {
        if (camera) {
            utils::Entity cameraEntity = camera->getEntity();
            engine->destroyCameraComponent(cameraEntity);
            EntityManager::get().destroy(cameraEntity);
        }
        
        if (skybox) {
            engine->destroy(skybox);
            self.skybox = nullptr;
        }
        
        if (self.iblTexture) {
            engine->destroy(self.iblTexture);
            self.iblTexture = nullptr;
        }
        
        // Release KTX bundle
        if (self.ktxBundle) {
            delete self.ktxBundle;
            self.ktxBundle = nullptr;
        }
        
        // Release texture data
        self.iblTextureData = nil;
        
        if (self.indirectLight) {
            engine->destroy(self.indirectLight);
            self.indirectLight = nullptr;
        }
        
        if (self.colorGrading) {
            engine->destroy(self.colorGrading);
            self.colorGrading = nullptr;
        }
        
        if (view) {
            engine->destroy(view);
        }
        if (scene) {
            engine->destroy(scene);
        }
        if (renderer) {
            engine->destroy(renderer);
        }
        if (swapChain) {
            engine->destroy(swapChain);
        }
        
        Engine::destroy(&engine);
        self.engine = nullptr;
    }
}

// ============================================================================
// MARK: - Material Debug Tools
// ============================================================================

- (void)randomizeCarPaint {
    if (!self.asset) {
        NSLog(@"[FilamentRenderer] ❌ No asset loaded");
        return;
    }
    
    // Generate random color
    float r = (float)arc4random_uniform(256) / 255.0f;
    float g = (float)arc4random_uniform(256) / 255.0f;
    float b = (float)arc4random_uniform(256) / 255.0f;
    
    // Find and update "carpaint" material specifically
    size_t entityCount = self.asset->getEntityCount();
    const utils::Entity* entities = self.asset->getEntities();
    auto& rcm = self.engine->getRenderableManager();
    
    int materialsUpdated = 0;
    
    for (size_t i = 0; i < entityCount; ++i) {
        auto instance = rcm.getInstance(entities[i]);
        if (!instance) continue;
        
        size_t primitiveCount = rcm.getPrimitiveCount(instance);
        for (size_t j = 0; j < primitiveCount; ++j) {
            MaterialInstance* matInstance = rcm.getMaterialInstanceAt(instance, j);
            if (!matInstance) continue;
            
            // Get material name to check if it's carpaint
            const char* matName = matInstance->getName();
            if (matName && (strstr(matName, "carpaint") != nullptr || strstr(matName, "CarPaint") != nullptr)) {
                // Use baseColorFactor (standard glTF PBR parameter)
                matInstance->setParameter("baseColorFactor", RgbType::sRGB, math::float3{r, g, b});
                materialsUpdated++;
                NSLog(@"[FilamentRenderer] 🎨 Updated material: %s", matName);
            }
        }
    }
    
    if (materialsUpdated > 0) {
        NSLog(@"[FilamentRenderer] 🎨 Random paint applied: RGB(%.2f, %.2f, %.2f) to %d carpaint materials",
              r, g, b, materialsUpdated);
    } else {
        NSLog(@"[FilamentRenderer] ⚠️ No 'carpaint' materials found in model");
    }
}

- (void)inspectMaterials {
    if (!self.asset) {
        NSLog(@"[FilamentRenderer] ❌ No asset loaded");
        return;
    }
    
    // Buffer output to avoid WiFi debugger lag (single NSLog instead of 15+)
    NSMutableString *output = [NSMutableString stringWithString:@"\n🔍 ========== MATERIAL INSPECTION ==========\n"];
    
    utils::Entity const* entities = self.asset->getEntities();
    size_t entityCount = self.asset->getEntityCount();
    auto& rm = self.engine->getRenderableManager();
    
    int totalEntities = 0;
    int totalPrimitives = 0;
    
    for (size_t i = 0; i < entityCount; ++i) {
        utils::Entity entity = entities[i];
        
        if (!rm.hasComponent(entity)) continue;
        
        auto instance = rm.getInstance(entity);
        size_t primCount = rm.getPrimitiveCount(instance);
        
        [output appendFormat:@"Entity %d: %zu primitives\n", entity.getId(), primCount];
        totalEntities++;
        totalPrimitives += primCount;
        
        for (size_t p = 0; p < primCount; ++p) {
            filament::MaterialInstance* mi = rm.getMaterialInstanceAt(instance, p);
            if (mi) {
                const filament::Material* mat = mi->getMaterial();
                [output appendFormat:@"  Prim %zu: %s\n", p, mat->getName()];
            }
        }
    }
    
    [output appendFormat:@"==========================================\n"];
    [output appendFormat:@"Total: %d entities, %d primitives", totalEntities, totalPrimitives];
    
    // Single NSLog call - much faster over WiFi debugger!
    NSLog(@"[FilamentRenderer] %@", output);
}

// ============================================================================
// MARK: - Memory Benchmark Tools
// ============================================================================

- (void)loadProceduralCube {
    NSLog(@"[FilamentRenderer] 🧊 Creating procedural cube (no textures, minimal geometry)...");
    
    // === 1. Get default material from engine ===
    // Use Filament's built-in default material (simple white)
    const filament::Material* defaultMaterial = self.engine->getDefaultMaterial();
    const filament::MaterialInstance* materialInstance = defaultMaterial->getDefaultInstance();
    
    NSLog(@"[FilamentRenderer] ✅ Using Filament default material");
    
    // === 2. Define cube vertices (8 vertices) ===
    struct Vertex {
        math::float3 position;
    };
    
    static const Vertex CUBE_VERTICES[8] = {
        {{-1.0f, -1.0f, -1.0f}},  // 0
        {{ 1.0f, -1.0f, -1.0f}},  // 1
        {{ 1.0f,  1.0f, -1.0f}},  // 2
        {{-1.0f,  1.0f, -1.0f}},  // 3
        {{-1.0f, -1.0f,  1.0f}},  // 4
        {{ 1.0f, -1.0f,  1.0f}},  // 5
        {{ 1.0f,  1.0f,  1.0f}},  // 6
        {{-1.0f,  1.0f,  1.0f}}   // 7
    };
    
    // === 3. Define indices (36 for 12 triangles) ===
    static const uint16_t CUBE_INDICES[36] = {
        0, 1, 2,  0, 2, 3,  // Front
        1, 5, 6,  1, 6, 2,  // Right
        5, 4, 7,  5, 7, 6,  // Back
        4, 0, 3,  4, 3, 7,  // Left
        3, 2, 6,  3, 6, 7,  // Top
        4, 5, 1,  4, 1, 0   // Bottom
    };
    
    // === 4. Create vertex buffer ===
    VertexBuffer* vertexBuffer = VertexBuffer::Builder()
        .vertexCount(8)
        .bufferCount(1)
        .attribute(VertexAttribute::POSITION, 0, VertexBuffer::AttributeType::FLOAT3, 0, sizeof(Vertex))
        .build(*self.engine);
    
    vertexBuffer->setBufferAt(*self.engine, 0, 
        VertexBuffer::BufferDescriptor(CUBE_VERTICES, sizeof(CUBE_VERTICES), nullptr));
    
    // === 5. Create index buffer ===
    IndexBuffer* indexBuffer = IndexBuffer::Builder()
        .indexCount(36)
        .bufferType(IndexBuffer::IndexType::USHORT)
        .build(*self.engine);
    
    indexBuffer->setBuffer(*self.engine,
        IndexBuffer::BufferDescriptor(CUBE_INDICES, sizeof(CUBE_INDICES), nullptr));
    
    // === 6. Create entity and renderable ===
    utils::Entity cubeEntity = utils::EntityManager::get().create();
    
    RenderableManager::Builder(1)
        .boundingBox({{ -1, -1, -1 }, { 1, 1, 1 }})
        .material(0, materialInstance)
        .geometry(0, RenderableManager::PrimitiveType::TRIANGLES, vertexBuffer, indexBuffer, 0, 36)
        .culling(false)
        .receiveShadows(false)
        .castShadows(false)
        .build(*self.engine, cubeEntity);
    
    // === 7. Add to scene ===
    self.scene->addEntity(cubeEntity);
    
    // === 8. Position cube at origin ===
    TransformManager& transformManager = self.engine->getTransformManager();
    auto instance = transformManager.getInstance(cubeEntity);
    transformManager.setTransform(instance, math::mat4f::translation(math::float3{0.0f, 0.0f, 0.0f}));
    
    NSLog(@"[FilamentRenderer] ✅ Procedural cube created:");
    NSLog(@"[FilamentRenderer]    • Vertices: 8");
    NSLog(@"[FilamentRenderer]    • Indices: 36");
    NSLog(@"[FilamentRenderer]    • Triangles: 12");
    NSLog(@"[FilamentRenderer]    • Textures: 0");
    NSLog(@"[FilamentRenderer]    • Memory: ~1KB geometry only");
}

// ============================================================================
// MARK: - Future Features (Placeholders)
// ============================================================================

- (void)loadCarWithVIN:(NSString *)vin {
    // TODO: Implement VIN-based car loading
    NSLog(@"[FilamentRenderer] VIN loading not implemented yet: %@", vin);
}

- (void)setEnvironmentTheme:(NSInteger)theme {
    // TODO: Implement environment themes
    NSLog(@"[FilamentRenderer] Environment themes not implemented yet: %ld", (long)theme);
}

- (void)enableRainEffect:(BOOL)enabled {
    // TODO: Implement rain VFX
    NSLog(@"[FilamentRenderer] Rain effects not implemented yet: %d", enabled);
}

- (void)swapCarPart:(NSString *)partId withPart:(NSString *)partPath {
    // TODO: Implement part swapping
    NSLog(@"[FilamentRenderer] Part swapping not implemented yet: %@ -> %@", partId, partPath);
}

// ============================================================================
// RUNTIME SGSR CONTROL
// ============================================================================

- (void)setDynamicResolutionScale:(float)scale {
    if (!self.view || !self.renderer || !self.engine) {
        NSLog(@"[FilamentRenderer] ⚠️ Cannot set resolution: view/renderer/engine not initialized");
        return;
    }
    
    // Clamp scale to reasonable range (0.25 - 1.0)
    scale = fmaxf(0.25f, fminf(1.0f, scale));
    
    NSLog(@"[FilamentRenderer] 🔄 Changing resolution to %.3f×...", scale);
    
    // STEP 1: Flush render pipeline completely
    if (self.renderer && self.swapChain) {
        // Render several frames to flush all pending GPU work
        for (int i = 0; i < 5; i++) {
            self.renderer->beginFrame(self.swapChain, 0);
            self.renderer->render(self.view);
            self.renderer->endFrame();
        }
    }
    
    // STEP 2: Flush Filament engine (force GPU completion)
    self.engine->flushAndWait();
    
    // STEP 3: Store and apply new scale
    self.currentResolutionScale = scale;
    
    View::DynamicResolutionOptions dr;
    dr.enabled = (scale < 1.0f);  // Disable if 100%
    dr.homogeneousScaling = true;
    dr.minScale = scale;
    dr.maxScale = scale;
    dr.quality = View::QualityLevel::MEDIUM;
    
    self.view->setDynamicResolutionOptions(dr);
    
    float resolutionPercent = scale * 100.0f;
    float pixelPercent = scale * scale * 100.0f;
    
    if (scale >= 1.0f) {
        NSLog(@"[FilamentRenderer] 🎯 SGSR DISABLED: Native (1.0×) - 100%% resolution, 100%% pixels");
    } else {
        NSLog(@"[FilamentRenderer] 🎯 SGSR %.3f× scale - %.0f%% resolution, %.0f%% pixels (Apple SGSR upscale)", 
              scale, resolutionPercent, pixelPercent);
    }
    
    // STEP 4: Force engine flush again + render multiple frames
    self.engine->flushAndWait();
    
    if (self.renderer && self.swapChain) {
        for (int i = 0; i < 5; i++) {
            self.renderer->beginFrame(self.swapChain, 0);
            self.renderer->render(self.view);
            self.renderer->endFrame();
        }
    }
    
    // STEP 5: Final flush to ensure buffers are freed
    self.engine->flushAndWait();
    
    NSLog(@"[FilamentRenderer] ✅ Resolution change complete");
}

- (float)getCurrentResolutionScale {
    return self.currentResolutionScale;
}

@end
