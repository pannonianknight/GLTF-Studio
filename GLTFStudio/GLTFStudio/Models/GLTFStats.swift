//
//  GLTFStats.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import Foundation

/// Statistics for glTF file before and after optimization
struct GLTFStats: Equatable, Sendable {
    
    // MARK: - File Information
    
    var inputPath: String
    var outputPath: String?
    
    // MARK: - File Sizes
    
    var inputSize: Int64 = 0
    var outputSize: Int64 = 0
    
    // MARK: - Processing Information
    
    var processingTime: TimeInterval = 0
    var startTime: Date?
    var endTime: Date?
    
    // MARK: - Model Information (parsed from gltfpack output)
    
    var vertexCount: Int?
    var triangleCount: Int?
    var meshCount: Int?
    var materialCount: Int?
    var textureCount: Int?
    
    // MARK: - Computed Properties
    
    var compressionRatio: Double {
        guard outputSize > 0, inputSize > 0 else { return 0 }
        return Double(outputSize) / Double(inputSize)
    }
    
    var compressionPercentage: Double {
        guard outputSize > 0, inputSize > 0 else { return 0 }
        return (1.0 - compressionRatio) * 100.0
    }
    
    var sizeSaved: Int64 {
        return inputSize - outputSize
    }
    
    var estimatedGPUMemory: Int64 {
        // Basic estimation: vertex count * average vertex size (assuming ~32 bytes per vertex)
        // This is a rough approximation
        guard let vertices = vertexCount else { return 0 }
        return Int64(vertices * 32)
    }
    
    // MARK: - Formatting Helpers
    
    var inputSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: inputSize, countStyle: .file)
    }
    
    var outputSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: outputSize, countStyle: .file)
    }
    
    var sizeSavedFormatted: String {
        return ByteCountFormatter.string(fromByteCount: sizeSaved, countStyle: .file)
    }
    
    var processingTimeFormatted: String {
        return String(format: "%.2f seconds", processingTime)
    }
    
    var compressionRatioFormatted: String {
        return String(format: "%.1f%%", compressionPercentage)
    }
    
    var estimatedGPUMemoryFormatted: String {
        return ByteCountFormatter.string(fromByteCount: estimatedGPUMemory, countStyle: .memory)
    }
    
    // MARK: - Initialization
    
    nonisolated init(inputPath: String, outputPath: String? = nil) {
        self.inputPath = inputPath
        self.outputPath = outputPath
        
        // Get input file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: inputPath),
           let size = attributes[.size] as? Int64 {
            self.inputSize = size
        }
    }
    
    // MARK: - Update Methods
    
    nonisolated mutating func startProcessing() {
        startTime = Date()
    }
    
    nonisolated mutating func finishProcessing() {
        endTime = Date()
        
        if let start = startTime, let end = endTime {
            processingTime = end.timeIntervalSince(start)
        }
        
        // Update output file size
        if let output = outputPath,
           let attributes = try? FileManager.default.attributesOfItem(atPath: output),
           let size = attributes[.size] as? Int64 {
            outputSize = size
        }
    }
    
    nonisolated mutating func updateOutputPath(_ path: String) {
        outputPath = path
        
        // Immediately get output file size if file exists
        if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attributes[.size] as? Int64 {
            outputSize = size
        }
    }
    
    // MARK: - Parsing from gltfpack output
    
    nonisolated mutating func parseGltfpackOutput(_ output: String) {
        // Parse output for statistics
        // Example lines:
        // "Meshes: 5"
        // "Triangles: 12340"
        // "Vertices: 8910"
        // "Materials: 3"
        // "Textures: 4"
        
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("Vertices:") {
                vertexCount = extractNumber(from: trimmed)
            } else if trimmed.hasPrefix("Triangles:") {
                triangleCount = extractNumber(from: trimmed)
            } else if trimmed.hasPrefix("Meshes:") {
                meshCount = extractNumber(from: trimmed)
            } else if trimmed.hasPrefix("Materials:") {
                materialCount = extractNumber(from: trimmed)
            } else if trimmed.hasPrefix("Textures:") {
                textureCount = extractNumber(from: trimmed)
            }
        }
    }
    
    private func extractNumber(from line: String) -> Int? {
        let components = line.components(separatedBy: ":")
        guard components.count >= 2 else { return nil }
        
        let numberString = components[1].trimmingCharacters(in: .whitespaces)
        return Int(numberString)
    }
}

// MARK: - Summary

extension GLTFStats {
    
    /// Generate a human-readable summary
    var summary: String {
        var lines: [String] = []
        
        lines.append("Input: \(inputSizeFormatted)")
        
        if outputSize > 0 {
            lines.append("Output: \(outputSizeFormatted)")
            lines.append("Saved: \(sizeSavedFormatted) (\(compressionRatioFormatted))")
        }
        
        if processingTime > 0 {
            lines.append("Time: \(processingTimeFormatted)")
        }
        
        if let vertices = vertexCount {
            lines.append("Vertices: \(vertices)")
        }
        
        if let triangles = triangleCount {
            lines.append("Triangles: \(triangles)")
        }
        
        if let meshes = meshCount {
            lines.append("Meshes: \(meshes)")
        }
        
        if estimatedGPUMemory > 0 {
            lines.append("Est. GPU Memory: \(estimatedGPUMemoryFormatted)")
        }
        
        return lines.joined(separator: "\n")
    }
}

