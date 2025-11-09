/*
 * CameraController.h
 * Core3D Camera Manager
 * 
 * Platform-agnostic camera control system
 * Handles presets, orbit controls, and smooth transitions
 */

#pragma once

#include "CameraTypes.h"
#include <string>
#include <unordered_map>

namespace core3d {

/**
 * CameraController - Platform-agnostic camera management
 * 
 * Responsibilities:
 * - Camera preset management (Front, Top, Rear, etc.)
 * - Smooth camera transitions (lerp)
 * - Orbit controls (pan, zoom, rotate)
 * - FOV calculations
 * 
 * Does NOT handle:
 * - Platform-specific gesture recognition
 * - Actual Filament camera API calls (caller does that)
 * - UI callbacks
 */
class CameraController {
public:
    CameraController();
    ~CameraController();
    
    // ========================================
    // Configuration
    // ========================================
    
    /**
     * Set camera lens configuration
     */
    void setConfig(const CameraConfig& config);
    
    /**
     * Set orbit constraints
     */
    void setOrbitConfig(const OrbitConfig& config);
    
    /**
     * Get current camera config
     */
    const CameraConfig& getConfig() const { return config_; }
    
    // ========================================
    // Preset Management
    // ========================================
    
    /**
     * Register a camera preset
     * @param name Preset name (e.g., "Front", "Top", "Rear")
     * @param preset Preset data
     */
    void registerPreset(const std::string& name, const CameraPreset& preset);
    
    /**
     * Move to a preset
     * @param name Preset name
     * @param smooth Use smooth transition
     * @return true if preset found and applied
     */
    bool moveToPreset(const std::string& name, bool smooth = true);
    
    /**
     * Get preset by name
     */
    const CameraPreset* getPreset(const std::string& name) const;
    
    // ========================================
    // Direct Control
    // ========================================
    
    /**
     * Set camera position and look-at directly
     */
    void setCamera(const Vector3& position, const Vector3& lookAt);
    
    /**
     * Get current camera state
     */
    const CameraState& getState() const { return currentState_; }
    
    // ========================================
    // Orbit Controls
    // ========================================
    
    /**
     * Enable/disable orbit controls
     */
    void setOrbitEnabled(bool enabled);
    
    /**
     * Check if orbit controls are enabled
     */
    bool isOrbitEnabled() const { return orbitEnabled_; }
    
    /**
     * Apply orbit rotation
     * @param deltaX Horizontal rotation delta (radians)
     * @param deltaY Vertical rotation delta (radians)
     */
    void applyOrbitRotation(float deltaX, float deltaY);
    
    /**
     * Apply orbit zoom
     * @param delta Zoom delta (positive = zoom in, negative = zoom out)
     */
    void applyOrbitZoom(float delta);
    
    /**
     * Initialize orbit rotation from current camera position
     */
    void initializeOrbitFromCamera();
    
    // ========================================
    // Animation Update
    // ========================================
    
    /**
     * Update camera state (call every frame)
     * Handles smooth transitions
     * @param deltaTime Time since last update in seconds
     */
    void update(float deltaTime);
    
    /**
     * Check if camera is currently moving/animating
     */
    bool isMoving() const { return currentState_.isMoving; }
    
    // ========================================
    // Utility
    // ========================================
    
    /**
     * Calculate vertical FOV in radians
     */
    float calculateVerticalFOV() const;
    
    /**
     * Calculate vertical FOV in degrees
     */
    float calculateVerticalFOVDegrees() const;
    
private:
    // Configuration
    CameraConfig config_;
    OrbitConfig orbitConfig_;
    
    // State
    CameraState currentState_;
    CameraState targetState_;
    
    // Presets
    std::unordered_map<std::string, CameraPreset> presets_;
    
    // Orbit
    bool orbitEnabled_ = false;
    
    // Smooth transition speed (units per second)
    float transitionSpeed_ = 5.0f;
    
    // Internal helpers
    Vector3 lerpVector(const Vector3& a, const Vector3& b, float t) const;
    Quaternion slerpQuaternion(const Quaternion& a, const Quaternion& b, float t) const;
    void updateOrbitCamera();
};

} // namespace core3d

