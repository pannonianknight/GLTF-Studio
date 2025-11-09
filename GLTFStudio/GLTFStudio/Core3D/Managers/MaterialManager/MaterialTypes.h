/*
 * MaterialTypes.h
 * Core3D Material Types and Structures
 * 
 * Platform-agnostic material configuration data
 */

#pragma once

#include <string>

namespace core3d {

// ============================================================================
// MaterialColor - RGBA color
// ============================================================================
struct MaterialColor {
    float r, g, b, a;
    
    MaterialColor() : r(1.0f), g(1.0f), b(1.0f), a(1.0f) {}
    MaterialColor(float r_, float g_, float b_, float a_ = 1.0f) 
        : r(r_), g(g_), b(b_), a(a_) {}
};

// ============================================================================
// PBRProperties - Physically-Based Rendering properties
// ============================================================================
struct PBRProperties {
    float metallic;       // 0.0 = dielectric, 1.0 = metallic
    float roughness;      // 0.0 = smooth, 1.0 = rough
    float reflectance;    // 0.0 - 1.0 (default 0.5)
    float clearCoat;      // 0.0 - 1.0 (default 0.0)
    float clearCoatRoughness;  // 0.0 - 1.0
    float anisotropy;     // 0.0 - 1.0 (default 0.0)
    
    PBRProperties()
        : metallic(0.0f)
        , roughness(0.5f)
        , reflectance(0.5f)
        , clearCoat(0.0f)
        , clearCoatRoughness(0.0f)
        , anisotropy(0.0f)
    {}
};

// ============================================================================
// TextureSlot - Texture identifiers
// ============================================================================
enum class TextureSlot {
    BaseColor,      // Albedo/diffuse
    Normal,         // Normal map
    Metallic,       // Metallic map
    Roughness,      // Roughness map
    AmbientOcclusion,  // AO map
    Emissive        // Emissive/glow map
};

// ============================================================================
// MaterialConfig - Complete material configuration
// ============================================================================
struct MaterialConfig {
    std::string name;
    MaterialColor baseColor;
    PBRProperties pbr;
    
    // Texture paths (optional)
    std::string baseColorTexture;
    std::string normalTexture;
    std::string metallicRoughnessTexture;
    std::string aoTexture;
    std::string emissiveTexture;
    
    bool doubleSided;
    bool unlit;  // Skip lighting calculations
    
    MaterialConfig()
        : name("DefaultMaterial")
        , doubleSided(false)
        , unlit(false)
    {}
};

// ============================================================================
// MaterialPreset - Predefined material configurations
// ============================================================================
enum class MaterialPreset {
    // Car paint
    GlossyPaint,        // Shiny car paint (high metallic, low roughness)
    MattePaint,         // Matte car paint (low metallic, high roughness)
    MetallicPaint,      // Metallic flake paint
    
    // Wheels
    Chrome,             // Chrome wheels (full metallic, smooth)
    AluminumAlloy,      // Aluminum alloy wheels
    
    // Interior
    Leather,            // Leather seats
    Fabric,             // Fabric seats
    Plastic,            // Dashboard plastic
    
    // Glass
    Glass,              // Transparent glass
    TintedGlass,        // Tinted windows
    
    // Misc
    Rubber,             // Tires
    Carbon              // Carbon fiber
};

} // namespace core3d

