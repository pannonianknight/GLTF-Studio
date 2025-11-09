/*
 * AnimationController.h
 * Core3D Animation Manager
 * 
 * Pure C++ animation controller - NO platform-specific code
 * Manages Filament gltfio::Animator lifecycle and playback
 */

#pragma once

#include "gltfio/Animator.h"
#include <cstddef>
#include <string>
#include <vector>

// Forward declare Filament types
namespace filament {
namespace gltfio {
class Animator;
}
}

namespace core3d {

/**
 * AnimationController - Platform-agnostic animation management
 * 
 * Responsibilities:
 * - Animation playback control (play/stop/pause)
 * - Time-based animation updates
 * - Animation state tracking
 * - Bone matrix updates
 * 
 * Does NOT handle:
 * - Platform-specific time sources (caller provides deltaTime)
 * - UI callbacks
 * - Asset loading
 */
class AnimationController {
public:
    /**
     * Constructor
     * @param animator Filament animator instance (NOT owned by this class)
     */
    explicit AnimationController(filament::gltfio::Animator* animator);
    
    ~AnimationController();
    
    // ========================================
    // Playback Control
    // ========================================
    
    /**
     * Start playing animation by index
     * @param index Animation index (0 to getAnimationCount()-1)
     * @param loop Whether to loop the animation
     */
    void play(size_t index, bool loop = false);
    
    /**
     * Start playing animation by name
     * @param name Animation name
     * @param loop Whether to loop the animation
     * @return true if animation found and started
     */
    bool play(const std::string& name, bool loop = false);
    
    /**
     * Stop current animation
     */
    void stop();
    
    /**
     * Pause current animation (can be resumed with resume())
     */
    void pause();
    
    /**
     * Resume paused animation
     */
    void resume();
    
    /**
     * Update animation state (call every frame)
     * @param deltaTime Time since last update in seconds
     */
    void update(float deltaTime);
    
    // ========================================
    // Animation Info
    // ========================================
    
    /**
     * Get total number of animations
     */
    size_t getAnimationCount() const;
    
    /**
     * Get animation name by index
     * @param index Animation index
     * @return Animation name or empty string if invalid index
     */
    std::string getAnimationName(size_t index) const;
    
    /**
     * Get all animation names
     */
    std::vector<std::string> getAnimationNames() const;
    
    /**
     * Get animation duration
     * @param index Animation index
     * @return Duration in seconds, or 0.0f if invalid
     */
    float getAnimationDuration(size_t index) const;
    
    /**
     * Find animation index by name
     * @param name Animation name
     * @return Index or SIZE_MAX if not found
     */
    size_t findAnimationByName(const std::string& name) const;
    
    // ========================================
    // State Queries
    // ========================================
    
    bool isPlaying() const { return isPlaying_; }
    bool isPaused() const { return isPaused_; }
    bool isLooping() const { return shouldLoop_; }
    
    size_t getCurrentIndex() const { return currentIndex_; }
    float getElapsedTime() const { return elapsedTime_; }
    float getDuration() const { return duration_; }
    float getProgress() const { return (duration_ > 0.0f) ? (elapsedTime_ / duration_) : 0.0f; }
    
private:
    filament::gltfio::Animator* animator_;  // External resource - NOT owned
    
    // Playback state
    bool isPlaying_ = false;
    bool isPaused_ = false;
    bool shouldLoop_ = false;
    
    // Current animation
    size_t currentIndex_ = 0;
    float elapsedTime_ = 0.0f;
    float duration_ = 0.0f;
    
    // Internal helpers
    void applyAnimationAtTime(size_t index, float time);
};

} // namespace core3d
