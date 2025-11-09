//
//  OptimizationConfig.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import Foundation

/// Texture compression format options
enum TextureFormat: String, Codable, CaseIterable {
    case etc1s = "ETC1S"
    case uastc = "UASTC"
    case none = "None"
    
    var displayName: String { rawValue }
}

/// Optimization preset types
enum OptimizationPreset: String, Codable, CaseIterable {
    case low = "Low Quality"
    case balanced = "Balanced"
    case high = "High Quality"
    case custom = "Custom"
    
    var displayName: String { rawValue }
}

/// Mesh optimization settings
struct MeshOptimization: Codable, Equatable {
    var compression: Bool
    var vertexPosition: Int // 8-16 bits
    var vertexTexCoord: Int // 8-16 bits
    var vertexNormal: Int // 8-16 bits
    
    static let `default` = MeshOptimization(
        compression: true,
        vertexPosition: 14,
        vertexTexCoord: 12,
        vertexNormal: 10
    )
    
    func validate() -> Bool {
        return (8...16).contains(vertexPosition) &&
               (8...16).contains(vertexTexCoord) &&
               (8...16).contains(vertexNormal)
    }
}

/// Texture optimization settings
struct TextureOptimization: Codable, Equatable {
    var enabled: Bool
    var format: TextureFormat
    var quality: Int // 1-255
    var maxDimension: Int // 256, 512, 1024, 2048, 4096
    var powerOfTwo: Bool
    
    static let `default` = TextureOptimization(
        enabled: true,
        format: .etc1s,
        quality: 128,
        maxDimension: 2048,
        powerOfTwo: true
    )
    
    func validate() -> Bool {
        return (1...255).contains(quality) &&
               [256, 512, 1024, 2048, 4096].contains(maxDimension)
    }
}

/// Complete optimization configuration
struct OptimizationConfig: Codable, Equatable {
    var name: String
    var preset: OptimizationPreset
    var mesh: MeshOptimization
    var texture: TextureOptimization
    
    static let `default` = OptimizationConfig(
        name: "Balanced",
        preset: .balanced,
        mesh: .default,
        texture: .default
    )
    
    // MARK: - Preset Configurations
    
    static let lowQuality = OptimizationConfig(
        name: "Low Quality",
        preset: .low,
        mesh: MeshOptimization(
            compression: true,
            vertexPosition: 12,
            vertexTexCoord: 10,
            vertexNormal: 8
        ),
        texture: TextureOptimization(
            enabled: true,
            format: .etc1s,
            quality: 1,
            maxDimension: 1024,
            powerOfTwo: true
        )
    )
    
    static let balanced = OptimizationConfig(
        name: "Balanced",
        preset: .balanced,
        mesh: MeshOptimization(
            compression: true,
            vertexPosition: 14,
            vertexTexCoord: 12,
            vertexNormal: 10
        ),
        texture: TextureOptimization(
            enabled: true,
            format: .etc1s,
            quality: 128,
            maxDimension: 2048,
            powerOfTwo: true
        )
    )
    
    static let highQuality = OptimizationConfig(
        name: "High Quality",
        preset: .high,
        mesh: MeshOptimization(
            compression: true,
            vertexPosition: 16,
            vertexTexCoord: 14,
            vertexNormal: 12
        ),
        texture: TextureOptimization(
            enabled: true,
            format: .uastc,
            quality: 10,
            maxDimension: 4096,
            powerOfTwo: false
        )
    )
    
    static let custom = OptimizationConfig(
        name: "Custom",
        preset: .custom,
        mesh: .default,
        texture: .default
    )
    
    // MARK: - Validation
    
    func validate() -> Bool {
        return mesh.validate() && texture.validate()
    }
    
    // MARK: - Preset Loading
    
    static func forPreset(_ preset: OptimizationPreset) -> OptimizationConfig {
        switch preset {
        case .low:
            return lowQuality
        case .balanced:
            return balanced
        case .high:
            return highQuality
        case .custom:
            return custom
        }
    }
    
    // MARK: - Command Generation
    
    func buildGltfpackArguments(inputPath: String, outputPath: String) -> [String] {
        var args: [String] = []
        
        // Input/Output
        args += ["-i", inputPath]
        args += ["-o", outputPath]
        
        // Mesh compression
        if mesh.compression {
            args.append("-cc")
        }
        
        // Vertex quantization
        args += ["-vp", "\(mesh.vertexPosition)"]
        args += ["-vt", "\(mesh.vertexTexCoord)"]
        args += ["-vn", "\(mesh.vertexNormal)"]
        
        // Texture compression
        if texture.enabled {
            args.append("-tc")
            
            switch texture.format {
            case .uastc:
                args.append("-tu")
            case .etc1s:
                // Default format, no additional flag
                break
            case .none:
                // Disable texture compression
                args.removeAll { $0 == "-tc" }
            }
            
            if texture.format != .none {
                args += ["-tq", "\(texture.quality)"]
            }
            
            // Texture resizing
            if texture.maxDimension < 4096 {
                args += ["-ts", "\(Double(texture.maxDimension))"]
            }
            
            // Power-of-two
            if texture.powerOfTwo {
                args.append("-tp")
            }
        }
        
        return args
    }
}

// MARK: - JSON Persistence

extension OptimizationConfig {
    
    /// Save configuration to JSON file
    func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
    
    /// Load configuration from JSON file
    static func load(from url: URL) throws -> OptimizationConfig {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(OptimizationConfig.self, from: data)
    }
    
    /// Load preset from bundle
    static func loadPreset(named name: String) -> OptimizationConfig? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Presets") else {
            return nil
        }
        return try? load(from: url)
    }
}

