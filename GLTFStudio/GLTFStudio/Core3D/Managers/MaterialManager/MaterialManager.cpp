/*
 * MaterialManager.cpp
 * Core3D Material Manager Implementation
 */

#include "MaterialManager.h"
#include <algorithm>

namespace core3d {

MaterialManager::MaterialManager() {
}

MaterialManager::~MaterialManager() {
}

// ========================================
// Material Configuration
// ========================================

void MaterialManager::setMaterial(const std::string& partName, const MaterialConfig& config) {
    materials_[partName] = config;
}

const MaterialConfig* MaterialManager::getMaterial(const std::string& partName) const {
    auto it = materials_.find(partName);
    if (it != materials_.end()) {
        return &it->second;
    }
    return nullptr;
}

bool MaterialManager::hasMaterial(const std::string& partName) const {
    return materials_.find(partName) != materials_.end();
}

// ========================================
// Quick Color/Property Setters
// ========================================

void MaterialManager::setBaseColor(const std::string& partName, float r, float g, float b, float a) {
    MaterialConfig& config = materials_[partName];
    config.baseColor = MaterialColor(clamp01(r), clamp01(g), clamp01(b), clamp01(a));
}

void MaterialManager::setPBRProperties(const std::string& partName, const PBRProperties& pbr) {
    materials_[partName].pbr = pbr;
}

void MaterialManager::setMetallic(const std::string& partName, float metallic) {
    materials_[partName].pbr.metallic = clamp01(metallic);
}

void MaterialManager::setRoughness(const std::string& partName, float roughness) {
    materials_[partName].pbr.roughness = clamp01(roughness);
}

void MaterialManager::setClearCoat(const std::string& partName, float clearCoat, float roughness) {
    materials_[partName].pbr.clearCoat = clamp01(clearCoat);
    materials_[partName].pbr.clearCoatRoughness = clamp01(roughness);
}

// ========================================
// Texture Management
// ========================================

void MaterialManager::setTexture(const std::string& partName, TextureSlot slot, const std::string& texturePath) {
    MaterialConfig& config = materials_[partName];
    
    switch (slot) {
        case TextureSlot::BaseColor:
            config.baseColorTexture = texturePath;
            break;
        case TextureSlot::Normal:
            config.normalTexture = texturePath;
            break;
        case TextureSlot::Metallic:
            config.metallicRoughnessTexture = texturePath;
            break;
        case TextureSlot::Roughness:
            config.metallicRoughnessTexture = texturePath;  // Often combined
            break;
        case TextureSlot::AmbientOcclusion:
            config.aoTexture = texturePath;
            break;
        case TextureSlot::Emissive:
            config.emissiveTexture = texturePath;
            break;
    }
}

std::string MaterialManager::getTexture(const std::string& partName, TextureSlot slot) const {
    auto it = materials_.find(partName);
    if (it == materials_.end()) {
        return "";
    }
    
    const MaterialConfig& config = it->second;
    
    switch (slot) {
        case TextureSlot::BaseColor:
            return config.baseColorTexture;
        case TextureSlot::Normal:
            return config.normalTexture;
        case TextureSlot::Metallic:
        case TextureSlot::Roughness:
            return config.metallicRoughnessTexture;
        case TextureSlot::AmbientOcclusion:
            return config.aoTexture;
        case TextureSlot::Emissive:
            return config.emissiveTexture;
    }
    
    return "";
}

// ========================================
// Presets
// ========================================

void MaterialManager::applyPreset(const std::string& partName, MaterialPreset preset) {
    MaterialConfig config = getPresetConfig(preset);
    config.name = partName + "_" + getPresetName(preset);
    setMaterial(partName, config);
}

MaterialConfig MaterialManager::getPresetConfig(MaterialPreset preset) {
    MaterialConfig config;
    
    switch (preset) {
        case MaterialPreset::GlossyPaint:
            config.name = "GlossyPaint";
            config.pbr.metallic = 0.8f;
            config.pbr.roughness = 0.2f;
            config.pbr.clearCoat = 1.0f;
            config.pbr.clearCoatRoughness = 0.1f;
            break;
            
        case MaterialPreset::MattePaint:
            config.name = "MattePaint";
            config.pbr.metallic = 0.0f;
            config.pbr.roughness = 0.8f;
            config.pbr.clearCoat = 0.0f;
            break;
            
        case MaterialPreset::MetallicPaint:
            config.name = "MetallicPaint";
            config.pbr.metallic = 0.9f;
            config.pbr.roughness = 0.3f;
            config.pbr.clearCoat = 0.8f;
            config.pbr.clearCoatRoughness = 0.15f;
            break;
            
        case MaterialPreset::Chrome:
            config.name = "Chrome";
            config.pbr.metallic = 1.0f;
            config.pbr.roughness = 0.05f;
            config.pbr.reflectance = 1.0f;
            break;
            
        case MaterialPreset::AluminumAlloy:
            config.name = "AluminumAlloy";
            config.pbr.metallic = 1.0f;
            config.pbr.roughness = 0.4f;
            config.pbr.reflectance = 0.9f;
            break;
            
        case MaterialPreset::Leather:
            config.name = "Leather";
            config.pbr.metallic = 0.0f;
            config.pbr.roughness = 0.6f;
            config.pbr.reflectance = 0.4f;
            break;
            
        case MaterialPreset::Fabric:
            config.name = "Fabric";
            config.pbr.metallic = 0.0f;
            config.pbr.roughness = 0.9f;
            config.pbr.reflectance = 0.3f;
            break;
            
        case MaterialPreset::Plastic:
            config.name = "Plastic";
            config.pbr.metallic = 0.0f;
            config.pbr.roughness = 0.5f;
            config.pbr.reflectance = 0.5f;
            break;
            
        case MaterialPreset::Glass:
            config.name = "Glass";
            config.pbr.metallic = 0.0f;
            config.pbr.roughness = 0.0f;
            config.pbr.reflectance = 0.5f;
            config.baseColor = MaterialColor(1.0f, 1.0f, 1.0f, 0.3f);  // Transparent
            break;
            
        case MaterialPreset::TintedGlass:
            config.name = "TintedGlass";
            config.pbr.metallic = 0.0f;
            config.pbr.roughness = 0.0f;
            config.pbr.reflectance = 0.5f;
            config.baseColor = MaterialColor(0.2f, 0.2f, 0.2f, 0.5f);  // Dark tint
            break;
            
        case MaterialPreset::Rubber:
            config.name = "Rubber";
            config.pbr.metallic = 0.0f;
            config.pbr.roughness = 0.85f;
            config.pbr.reflectance = 0.35f;
            config.baseColor = MaterialColor(0.1f, 0.1f, 0.1f, 1.0f);  // Dark
            break;
            
        case MaterialPreset::Carbon:
            config.name = "CarbonFiber";
            config.pbr.metallic = 0.2f;
            config.pbr.roughness = 0.4f;
            config.pbr.anisotropy = 0.8f;  // Carbon fiber weave pattern
            config.baseColor = MaterialColor(0.05f, 0.05f, 0.05f, 1.0f);
            break;
    }
    
    return config;
}

const char* MaterialManager::getPresetName(MaterialPreset preset) {
    switch (preset) {
        case MaterialPreset::GlossyPaint: return "GlossyPaint";
        case MaterialPreset::MattePaint: return "MattePaint";
        case MaterialPreset::MetallicPaint: return "MetallicPaint";
        case MaterialPreset::Chrome: return "Chrome";
        case MaterialPreset::AluminumAlloy: return "AluminumAlloy";
        case MaterialPreset::Leather: return "Leather";
        case MaterialPreset::Fabric: return "Fabric";
        case MaterialPreset::Plastic: return "Plastic";
        case MaterialPreset::Glass: return "Glass";
        case MaterialPreset::TintedGlass: return "TintedGlass";
        case MaterialPreset::Rubber: return "Rubber";
        case MaterialPreset::Carbon: return "CarbonFiber";
    }
    return "Unknown";
}

// ========================================
// Batch Operations
// ========================================

void MaterialManager::setColorForParts(const std::vector<std::string>& partNames, float r, float g, float b, float a) {
    for (const std::string& partName : partNames) {
        setBaseColor(partName, r, g, b, a);
    }
}

void MaterialManager::clear() {
    materials_.clear();
}

std::vector<std::string> MaterialManager::getAllPartNames() const {
    std::vector<std::string> names;
    names.reserve(materials_.size());
    
    for (const auto& pair : materials_) {
        names.push_back(pair.first);
    }
    
    return names;
}

// ========================================
// Internal Helpers
// ========================================

float MaterialManager::clamp01(float value) const {
    return std::max(0.0f, std::min(1.0f, value));
}

} // namespace core3d

