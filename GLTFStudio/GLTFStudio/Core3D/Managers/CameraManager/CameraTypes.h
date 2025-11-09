/*
 * CameraTypes.h
 * Core3D Camera Types and Structures
 * 
 * Platform-agnostic camera data structures
 */

#pragma once

#include <cmath>

namespace core3d {

// ============================================================================
// Vector3 - Simple 3D vector (platform-agnostic)
// ============================================================================
struct Vector3 {
    float x, y, z;
    
    Vector3() : x(0), y(0), z(0) {}
    Vector3(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}
    
    // Vector operations
    Vector3 operator+(const Vector3& other) const {
        return Vector3(x + other.x, y + other.y, z + other.z);
    }
    
    Vector3 operator-(const Vector3& other) const {
        return Vector3(x - other.x, y - other.y, z - other.z);
    }
    
    Vector3 operator*(float scalar) const {
        return Vector3(x * scalar, y * scalar, z * scalar);
    }
    
    float length() const {
        return sqrtf(x * x + y * y + z * z);
    }
    
    Vector3 normalized() const {
        float len = length();
        if (len > 0.0f) {
            return Vector3(x / len, y / len, z / len);
        }
        return Vector3(0, 0, 0);
    }
};

// ============================================================================
// Quaternion - Simple quaternion for rotations
// ============================================================================
struct Quaternion {
    float x, y, z, w;
    
    Quaternion() : x(0), y(0), z(0), w(1) {}
    Quaternion(float x_, float y_, float z_, float w_) : x(x_), y(y_), z(z_), w(w_) {}
};

// ============================================================================
// CameraPreset - Predefined camera positions
// ============================================================================
struct CameraPreset {
    Vector3 position;
    Vector3 lookAt;
    
    CameraPreset() {}
    CameraPreset(const Vector3& pos, const Vector3& look) 
        : position(pos), lookAt(look) {}
};

// ============================================================================
// CameraState - Current camera state
// ============================================================================
struct CameraState {
    Vector3 position;
    Vector3 lookAt;
    Vector3 upVector;
    
    // Orbit state
    Quaternion orbitRotation;
    float orbitDistance;
    
    // Animation state
    bool isMoving;
    
    CameraState() 
        : upVector(0, 1, 0)
        , orbitDistance(10.0f)
        , isMoving(false) 
    {}
};

// ============================================================================
// CameraConfig - Camera lens configuration
// ============================================================================
struct CameraConfig {
    float focalLengthMM;     // Focal length in millimeters
    float sensorHeightMM;    // Sensor height in millimeters
    float aspectRatio;       // Width / Height
    float nearPlane;         // Near clipping plane
    float farPlane;          // Far clipping plane
    
    CameraConfig()
        : focalLengthMM(80.0f)
        , sensorHeightMM(24.0f)
        , aspectRatio(16.0f / 9.0f)
        , nearPlane(0.1f)
        , farPlane(1000.0f)
    {}
    
    // Calculate vertical FOV from focal length
    float calculateVerticalFOV() const {
        return 2.0f * atanf(sensorHeightMM / (2.0f * focalLengthMM));
    }
    
    // Calculate vertical FOV in degrees
    float calculateVerticalFOVDegrees() const {
        return calculateVerticalFOV() * 180.0f / 3.14159265359f;
    }
};

// ============================================================================
// OrbitConfig - Orbit control constraints
// ============================================================================
struct OrbitConfig {
    float minDistance;
    float maxDistance;
    Vector3 target;
    
    OrbitConfig()
        : minDistance(2.0f)
        , maxDistance(50.0f)
        , target(0, 0, 0)
    {}
};

} // namespace core3d

