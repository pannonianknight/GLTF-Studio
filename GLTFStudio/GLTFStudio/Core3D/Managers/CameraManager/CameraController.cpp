/*
 * CameraController.cpp
 * Core3D Camera Manager Implementation
 */

#include "CameraController.h"
#include <cmath>
#include <algorithm>

namespace core3d {

CameraController::CameraController() {
    // Initialize with default up vector
    currentState_.upVector = Vector3(0, 1, 0);
    targetState_.upVector = Vector3(0, 1, 0);
}

CameraController::~CameraController() {
}

// ========================================
// Configuration
// ========================================

void CameraController::setConfig(const CameraConfig& config) {
    config_ = config;
}

void CameraController::setOrbitConfig(const OrbitConfig& config) {
    orbitConfig_ = config;
}

// ========================================
// Preset Management
// ========================================

void CameraController::registerPreset(const std::string& name, const CameraPreset& preset) {
    presets_[name] = preset;
}

bool CameraController::moveToPreset(const std::string& name, bool smooth) {
    auto it = presets_.find(name);
    if (it == presets_.end()) {
        return false;
    }
    
    const CameraPreset& preset = it->second;
    
    if (smooth) {
        // Set target and enable smooth transition
        targetState_.position = preset.position;
        targetState_.lookAt = preset.lookAt;
        currentState_.isMoving = true;
    } else {
        // Jump immediately
        currentState_.position = preset.position;
        currentState_.lookAt = preset.lookAt;
        targetState_.position = preset.position;
        targetState_.lookAt = preset.lookAt;
        currentState_.isMoving = false;
    }
    
    return true;
}

const CameraPreset* CameraController::getPreset(const std::string& name) const {
    auto it = presets_.find(name);
    if (it != presets_.end()) {
        return &it->second;
    }
    return nullptr;
}

// ========================================
// Direct Control
// ========================================

void CameraController::setCamera(const Vector3& position, const Vector3& lookAt) {
    currentState_.position = position;
    currentState_.lookAt = lookAt;
    targetState_.position = position;
    targetState_.lookAt = lookAt;
    currentState_.isMoving = false;
    
    // Update orbit distance
    Vector3 dir = position - lookAt;
    currentState_.orbitDistance = dir.length();
}

// ========================================
// Orbit Controls
// ========================================

void CameraController::setOrbitEnabled(bool enabled) {
    orbitEnabled_ = enabled;
    
    if (enabled) {
        // Initialize orbit from current camera position
        initializeOrbitFromCamera();
    }
}

void CameraController::applyOrbitRotation(float deltaX, float deltaY) {
    if (!orbitEnabled_) return;
    
    // Simple euler-based rotation (can be improved with quaternions)
    // For now, we'll update the orbit rotation and recalculate camera position
    
    // TODO: Implement proper quaternion-based rotation
    // For MVP, we'll just update the camera position directly
    
    Vector3 dir = currentState_.position - orbitConfig_.target;
    float distance = dir.length();
    
    // Spherical coordinates
    float theta = atan2f(dir.x, dir.z);  // Horizontal angle
    float phi = acosf(dir.y / distance); // Vertical angle
    
    // Apply deltas
    theta += deltaX;
    phi = std::clamp(phi + deltaY, 0.1f, 3.04f);  // Clamp to avoid gimbal lock
    
    // Convert back to cartesian
    Vector3 newPos;
    newPos.x = distance * sinf(phi) * sinf(theta);
    newPos.y = distance * cosf(phi);
    newPos.z = distance * sinf(phi) * cosf(theta);
    
    currentState_.position = orbitConfig_.target + newPos;
    currentState_.lookAt = orbitConfig_.target;
    targetState_.position = currentState_.position;
    targetState_.lookAt = currentState_.lookAt;
}

void CameraController::applyOrbitZoom(float delta) {
    if (!orbitEnabled_) return;
    
    Vector3 dir = currentState_.position - orbitConfig_.target;
    float currentDistance = dir.length();
    
    // Apply zoom
    float newDistance = std::clamp(
        currentDistance + delta,
        orbitConfig_.minDistance,
        orbitConfig_.maxDistance
    );
    
    // Scale direction vector to new distance
    if (currentDistance > 0.0f) {
        Vector3 normalizedDir = dir * (1.0f / currentDistance);
        currentState_.position = orbitConfig_.target + normalizedDir * newDistance;
        currentState_.orbitDistance = newDistance;
        
        targetState_.position = currentState_.position;
    }
}

void CameraController::initializeOrbitFromCamera() {
    Vector3 dir = currentState_.position - orbitConfig_.target;
    currentState_.orbitDistance = dir.length();
    targetState_.orbitDistance = currentState_.orbitDistance;
}

// ========================================
// Animation Update
// ========================================

void CameraController::update(float deltaTime) {
    if (!currentState_.isMoving) {
        return;
    }
    
    // Lerp position
    Vector3 positionDiff = targetState_.position - currentState_.position;
    float positionDistance = positionDiff.length();
    
    Vector3 lookAtDiff = targetState_.lookAt - currentState_.lookAt;
    float lookAtDistance = lookAtDiff.length();
    
    // Check if close enough to target
    if (positionDistance < 0.01f && lookAtDistance < 0.01f) {
        currentState_.position = targetState_.position;
        currentState_.lookAt = targetState_.lookAt;
        currentState_.isMoving = false;
        return;
    }
    
    // Smooth interpolation
    float t = std::min(deltaTime * transitionSpeed_, 1.0f);
    currentState_.position = lerpVector(currentState_.position, targetState_.position, t);
    currentState_.lookAt = lerpVector(currentState_.lookAt, targetState_.lookAt, t);
}

// ========================================
// Utility
// ========================================

float CameraController::calculateVerticalFOV() const {
    return config_.calculateVerticalFOV();
}

float CameraController::calculateVerticalFOVDegrees() const {
    return config_.calculateVerticalFOVDegrees();
}

// ========================================
// Internal Helpers
// ========================================

Vector3 CameraController::lerpVector(const Vector3& a, const Vector3& b, float t) const {
    return a + (b - a) * t;
}

Quaternion CameraController::slerpQuaternion(const Quaternion& a, const Quaternion& b, float t) const {
    // Simplified slerp for now
    // TODO: Implement proper spherical interpolation
    Quaternion result;
    result.x = a.x + (b.x - a.x) * t;
    result.y = a.y + (b.y - a.y) * t;
    result.z = a.z + (b.z - a.z) * t;
    result.w = a.w + (b.w - a.w) * t;
    return result;
}

void CameraController::updateOrbitCamera() {
    // TODO: Update camera based on orbit quaternion
    // For now, orbit is handled directly in applyOrbitRotation
}

} // namespace core3d

