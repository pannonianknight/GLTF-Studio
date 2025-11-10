//
//  GLTFParser.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//  Lightweight glTF/GLB parser for detecting animations and features
//

import Foundation

/// Lightweight parser for glTF/GLB files
actor GLTFParser {
    
    struct GLTFInfo {
        var hasAnimations: Bool = false
        var animationCount: Int = 0
        var hasSkins: Bool = false
        var skinCount: Int = 0
        var hasMorphTargets: Bool = false
        var meshCount: Int = 0
        var nodeCount: Int = 0
    }
    
    // MARK: - Public API
    
    /// Parse glTF/GLB file and extract information
    func parseFile(at url: URL) throws -> GLTFInfo {
        let ext = url.pathExtension.lowercased()
        
        if ext == "glb" {
            return try parseGLB(at: url)
        } else if ext == "gltf" {
            return try parseGLTF(at: url)
        } else {
            throw ParsingError.unsupportedFormat
        }
    }
    
    // MARK: - GLB Parsing
    
    /// Parse GLB binary file
    private func parseGLB(at url: URL) throws -> GLTFInfo {
        let data = try Data(contentsOf: url)
        
        guard data.count >= 12 else {
            throw ParsingError.invalidFile(reason: "File too small to be valid GLB")
        }
        
        // GLB header: magic (4 bytes) + version (4 bytes) + length (4 bytes)
        let magic = data.subdata(in: 0..<4)
        let magicString = String(data: magic, encoding: .ascii)
        
        guard magicString == "glTF" else {
            throw ParsingError.invalidFile(reason: "Not a valid GLB file (magic mismatch)")
        }
        
        // Read JSON chunk
        // GLB structure: Header (12) + JSON chunk header (8) + JSON data + Binary chunk (optional)
        guard data.count >= 20 else {
            throw ParsingError.invalidFile(reason: "GLB file truncated")
        }
        
        // JSON chunk length (bytes 12-15)
        let jsonLength = data.subdata(in: 12..<16).withUnsafeBytes { $0.load(as: UInt32.self) }
        
        // JSON chunk type (bytes 16-19) - should be 0x4E4F534A ("JSON")
        let jsonType = data.subdata(in: 16..<20)
        guard String(data: jsonType, encoding: .ascii) == "JSON" else {
            throw ParsingError.invalidFile(reason: "Invalid JSON chunk type")
        }
        
        // Extract JSON data
        let jsonStart = 20
        let jsonEnd = jsonStart + Int(jsonLength)
        
        guard data.count >= jsonEnd else {
            throw ParsingError.invalidFile(reason: "JSON chunk truncated")
        }
        
        let jsonData = data.subdata(in: jsonStart..<jsonEnd)
        
        return try parseGLTFJSON(jsonData)
    }
    
    // MARK: - glTF Parsing
    
    /// Parse glTF JSON file
    private func parseGLTF(at url: URL) throws -> GLTFInfo {
        let data = try Data(contentsOf: url)
        return try parseGLTFJSON(data)
    }
    
    // MARK: - JSON Parsing
    
    /// Parse glTF JSON structure
    private func parseGLTFJSON(_ data: Data) throws -> GLTFInfo {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ParsingError.invalidJSON
        }
        
        var info = GLTFInfo()
        
        // Check for animations
        if let animations = json["animations"] as? [[String: Any]] {
            info.hasAnimations = !animations.isEmpty
            info.animationCount = animations.count
        }
        
        // Check for skins (skeletal animation)
        if let skins = json["skins"] as? [[String: Any]] {
            info.hasSkins = !skins.isEmpty
            info.skinCount = skins.count
        }
        
        // Check for morph targets
        if let meshes = json["meshes"] as? [[String: Any]] {
            info.meshCount = meshes.count
            
            for mesh in meshes {
                if let primitives = mesh["primitives"] as? [[String: Any]] {
                    for primitive in primitives {
                        if let targets = primitive["targets"] as? [[String: Any]], !targets.isEmpty {
                            info.hasMorphTargets = true
                            break
                        }
                    }
                }
                if info.hasMorphTargets { break }
            }
        }
        
        // Check for nodes
        if let nodes = json["nodes"] as? [[String: Any]] {
            info.nodeCount = nodes.count
        }
        
        return info
    }
    
    // MARK: - Quick Checks
    
    /// Quick check if file has animations (without full parsing)
    func hasAnimations(at url: URL) throws -> Bool {
        let info = try parseFile(at: url)
        return info.hasAnimations
    }
    
    /// Get summary string
    func getSummary(for url: URL) throws -> String {
        let info = try parseFile(at: url)
        
        var summary: [String] = []
        
        if info.hasAnimations {
            summary.append("🎬 \(info.animationCount) animation(s)")
        }
        
        if info.hasSkins {
            summary.append("🦴 \(info.skinCount) skin(s)")
        }
        
        if info.hasMorphTargets {
            summary.append("🎭 Morph targets")
        }
        
        summary.append("📦 \(info.meshCount) mesh(es)")
        summary.append("🔗 \(info.nodeCount) node(s)")
        
        return summary.joined(separator: " • ")
    }
}

// MARK: - Errors

enum ParsingError: LocalizedError {
    case unsupportedFormat
    case invalidFile(reason: String)
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported file format (must be .glb or .gltf)"
        case .invalidFile(let reason):
            return "Invalid file: \(reason)"
        case .invalidJSON:
            return "Failed to parse glTF JSON"
        }
    }
}

