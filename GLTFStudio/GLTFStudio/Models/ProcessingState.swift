//
//  ProcessingState.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import Foundation

/// Represents the current state of the optimization process
enum ProcessingState: Equatable {
    case idle
    case processing(progress: Double?)
    case completed(stats: GLTFStats)
    case failed(error: ProcessingError)
    
    var isProcessing: Bool {
        if case .processing = self {
            return true
        }
        return false
    }
    
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
    
    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
    
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
    
    var stats: GLTFStats? {
        if case .completed(let stats) = self {
            return stats
        }
        return nil
    }
    
    var error: ProcessingError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

/// Custom errors for processing operations
enum ProcessingError: LocalizedError, Equatable {
    case fileNotFound(path: String)
    case invalidFile(reason: String)
    case gltfpackNotFound
    case gltfpackExecutionFailed(output: String)
    case invalidConfiguration(reason: String)
    case permissionDenied(path: String)
    case diskFull
    case cancelled
    case unknown(message: String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidFile(let reason):
            return "Invalid file: \(reason)"
        case .gltfpackNotFound:
            return "gltfpack binary not found in app bundle. Please rebuild the app with gltfpack included."
        case .gltfpackExecutionFailed(let output):
            return "Optimization failed:\n\(output)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .permissionDenied(let path):
            return "Permission denied: \(path)"
        case .diskFull:
            return "Not enough disk space to complete the operation"
        case .cancelled:
            return "Operation cancelled by user"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Make sure the file exists and try again."
        case .invalidFile:
            return "Choose a valid glTF (.gltf) or GLB (.glb) file."
        case .gltfpackNotFound:
            return "Reinstall the application or build from source with gltfpack included."
        case .gltfpackExecutionFailed:
            return "Check the file for corruption or try different optimization settings."
        case .invalidConfiguration:
            return "Adjust your settings and try again."
        case .permissionDenied:
            return "Grant file access permissions to the app."
        case .diskFull:
            return "Free up disk space and try again."
        case .cancelled:
            return nil
        case .unknown:
            return "Please report this issue with the error details."
        }
    }
}

// MARK: - Observable State Management

import Combine

/// ObservableObject for managing application state
@MainActor
class AppState: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var processingState: ProcessingState = .idle
    @Published var selectedPreset: OptimizationPreset = .low
    @Published var config: OptimizationConfig = .lowQuality
    @Published var inputFileURL: URL?
    @Published var outputFileURL: URL?
    
    // MARK: - File Selection
    
    func selectInputFile(_ url: URL) {
        print("📁 [APPSTATE] Input file selected: \(url.lastPathComponent)")
        inputFileURL = url
        
        // Auto-generate output filename
        let filename = url.deletingPathExtension().lastPathComponent
        let directory = url.deletingLastPathComponent()
        let ext = url.pathExtension
        let outputFilename = "\(filename)_optimized.\(ext)"
        outputFileURL = directory.appendingPathComponent(outputFilename)
        print("📁 [APPSTATE] Output auto-generated: \(outputFilename)")
    }
    
    func selectOutputFile(_ url: URL) {
        print("📁 [APPSTATE] Output file changed: \(url.lastPathComponent)")
        outputFileURL = url
    }
    
    // MARK: - Preset Management
    
    func selectPreset(_ preset: OptimizationPreset) {
        print("⚙️  [APPSTATE] Preset changed: \(preset.rawValue)")
        selectedPreset = preset
        config = OptimizationConfig.forPreset(preset)
    }
    
    func updateCustomConfig(_ newConfig: OptimizationConfig) {
        print("⚙️  [APPSTATE] Custom config updated")
        config = newConfig
        selectedPreset = .custom
    }
    
    // MARK: - Processing State Management
    
    func startProcessing() {
        processingState = .processing(progress: nil)
    }
    
    func updateProgress(_ progress: Double) {
        processingState = .processing(progress: progress)
    }
    
    func completeProcessing(stats: GLTFStats) {
        processingState = .completed(stats: stats)
    }
    
    func failProcessing(error: ProcessingError) {
        processingState = .failed(error: error)
    }
    
    func resetProcessing() {
        processingState = .idle
    }
    
    // MARK: - Validation
    
    func validateInputs() -> Result<Void, ProcessingError> {
        guard let input = inputFileURL else {
            return .failure(.invalidFile(reason: "No input file selected"))
        }
        
        guard FileManager.default.fileExists(atPath: input.path) else {
            return .failure(.fileNotFound(path: input.path))
        }
        
        let ext = input.pathExtension.lowercased()
        guard ext == "glb" || ext == "gltf" else {
            return .failure(.invalidFile(reason: "File must be .glb or .gltf"))
        }
        
        guard let _ = outputFileURL else {
            return .failure(.invalidFile(reason: "No output file specified"))
        }
        
        guard config.validate() else {
            return .failure(.invalidConfiguration(reason: "Configuration values out of range"))
        }
        
        return .success(())
    }
}

