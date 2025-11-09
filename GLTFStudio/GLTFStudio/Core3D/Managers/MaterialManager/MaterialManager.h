/*
 * MaterialManager.h
 * Core3D Material Manager
 * 
 * Platform-agnostic material configuration management
 * Stores material parameters - actual Filament material application done by platform layer
 */

#pragma once

#include "MaterialTypes.h"
#include <string>
#include <unordered_map>
#include <vector>

namespace core3d {

/**
 * MaterialManager - Platform-agnostic material management
 * 
 * Responsibilities:
 * - Store material configurations per part
 * - Provide material presets
 * - Calculate PBR parameters
 * - Track material changes
 * 
 * Does NOT handle:
 * - Actual Filament material instance creation
 * - Texture loading/GPU upload
 * - Shader compilation
 */
class MaterialManager {
public:
    MaterialManager();
    ~MaterialManager();
    
    // ========================================
    // Material Configuration
    // ========================================
    
    /**
     * Set material for a part
     * @param partName Part identifier (e.g., "Body", "Wheels", "Interior")
     * @param config Material configuration
     */
    void setMaterial(const std::string& partName, const MaterialConfig& config);
    
    /**
     * Get material configuration for a part
     * @param partName Part identifier
     * @return Pointer to config or nullptr if not found
     */
    const MaterialConfig* getMaterial(const std::string& partName) const;
    
    /**
     * Check if part has custom material
     */
    bool hasMaterial(const std::string& partName) const;
    
    // ========================================
    // Quick Color/Property Setters
    // ========================================
    
    /**
     * Set base color for a part
     */
    void setBaseColor(const std::string& partName, float r, float g, float b, float a = 1.0f);
    
    /**
     * Set PBR properties for a part
     */
    void setPBRProperties(const std::string& partName, const PBRProperties& pbr);
    
    /**
     * Set metallic value
     */
    void setMetallic(const std::string& partName, float metallic);
    
    /**
     * Set roughness value
     */
    void setRoughness(const std::string& partName, float roughness);
    
    /**
     * Set clear coat (for car paint)
     */
    void setClearCoat(const std::string& partName, float clearCoat, float roughness);
    
    // ========================================
    // Texture Management
    // ========================================
    
    /**
     * Set texture path for a part and slot
     */
    void setTexture(const std::string& partName, TextureSlot slot, const std::string& texturePath);
    
    /**
     * Get texture path for a part and slot
     */
    std::string getTexture(const std::string& partName, TextureSlot slot) const;
    
    // ========================================
    // Presets
    // ========================================
    
    /**
     * Apply material preset to a part
     */
    void applyPreset(const std::string& partName, MaterialPreset preset);
    
    /**
     * Get MaterialConfig for a preset
     */
    static MaterialConfig getPresetConfig(MaterialPreset preset);
    
    /**
     * Get preset name as string
     */
    static const char* getPresetName(MaterialPreset preset);
    
    // ========================================
    // Batch Operations
    // ========================================
    
    /**
     * Apply same color to multiple parts
     */
    void setColorForParts(const std::vector<std::string>& partNames, float r, float g, float b, float a = 1.0f);
    
    /**
     * Clear all material configurations
     */
    void clear();
    
    /**
     * Get all configured part names
     */
    std::vector<std::string> getAllPartNames() const;
    
private:
    std::unordered_map<std::string, MaterialConfig> materials_;
    
    // Validation helpers
    float clamp01(float value) const;
};

} // namespace core3d

