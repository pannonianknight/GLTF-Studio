/*
 * AnimationController.cpp
 * Core3D Animation Manager Implementation
 */

#include "AnimationController.h"
#include <algorithm>

namespace core3d {

AnimationController::AnimationController(filament::gltfio::Animator* animator)
    : animator_(animator) {
}

AnimationController::~AnimationController() {
    // animator_ is NOT owned by us, so we don't delete it
}

// ========================================
// Playback Control
// ========================================

void AnimationController::play(size_t index, bool loop) {
    if (!animator_ || index >= animator_->getAnimationCount()) {
        return;
    }
    
    currentIndex_ = index;
    duration_ = animator_->getAnimationDuration(index);
    elapsedTime_ = 0.0f;
    isPlaying_ = true;
    isPaused_ = false;
    shouldLoop_ = loop;
}

bool AnimationController::play(const std::string& name, bool loop) {
    size_t index = findAnimationByName(name);
    if (index == SIZE_MAX) {
        return false;
    }
    
    play(index, loop);
    return true;
}

void AnimationController::stop() {
    isPlaying_ = false;
    isPaused_ = false;
    // DON'T reset currentIndex_ - keep it for logging/debugging
    elapsedTime_ = 0.0f;
    shouldLoop_ = false;
}

void AnimationController::pause() {
    if (isPlaying_) {
        isPaused_ = true;
    }
}

void AnimationController::resume() {
    if (isPaused_) {
        isPaused_ = false;
    }
}

void AnimationController::update(float deltaTime) {
    if (!isPlaying_ || isPaused_ || !animator_) {
        return;
    }
    
    elapsedTime_ += deltaTime;
    
    // Check if animation finished
    if (elapsedTime_ >= duration_) {
        if (shouldLoop_) {
            // Loop: wrap time
            elapsedTime_ = fmodf(elapsedTime_, duration_);
        } else {
            // Finished: clamp to end and stop
            elapsedTime_ = duration_;
            stop();
            return;
        }
    }
    
    // Apply animation at current time
    applyAnimationAtTime(currentIndex_, elapsedTime_);
}

// ========================================
// Animation Info
// ========================================

size_t AnimationController::getAnimationCount() const {
    if (!animator_) return 0;
    return animator_->getAnimationCount();
}

std::string AnimationController::getAnimationName(size_t index) const {
    if (!animator_ || index >= animator_->getAnimationCount()) {
        return "";
    }
    
    const char* name = animator_->getAnimationName(index);
    return name ? std::string(name) : "";
}

std::vector<std::string> AnimationController::getAnimationNames() const {
    std::vector<std::string> names;
    size_t count = getAnimationCount();
    names.reserve(count);
    
    for (size_t i = 0; i < count; ++i) {
        names.push_back(getAnimationName(i));
    }
    
    return names;
}

float AnimationController::getAnimationDuration(size_t index) const {
    if (!animator_ || index >= animator_->getAnimationCount()) {
        return 0.0f;
    }
    
    return animator_->getAnimationDuration(index);
}

size_t AnimationController::findAnimationByName(const std::string& name) const {
    size_t count = getAnimationCount();
    for (size_t i = 0; i < count; ++i) {
        if (getAnimationName(i) == name) {
            return i;
        }
    }
    return SIZE_MAX;
}

// ========================================
// Internal Helpers
// ========================================

void AnimationController::applyAnimationAtTime(size_t index, float time) {
    if (!animator_) return;
    
    // Apply animation transformation at given time
    animator_->applyAnimation(index, time);
    
    // Update bone matrices for rendering
    animator_->updateBoneMatrices();
}

} // namespace core3d
