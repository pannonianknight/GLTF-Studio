//
//  GLTFPackService.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import Foundation

/// Service for running gltfpack optimization
actor GLTFPackService {
    
    private let processRunner = ProcessRunner()
    private let gltfParser = GLTFParser()
    
    // MARK: - Binary Location
    
    /// Get the path to the bundled gltfpack binary
    private func getGltfpackPath() -> String? {
        // Try to find in bundle Resources/Binaries
        if let path = Bundle.main.path(forResource: "gltfpack", ofType: nil, inDirectory: "Binaries") {
            return path
        }
        
        // Try alternative location (root of Resources)
        if let path = Bundle.main.path(forResource: "gltfpack", ofType: nil) {
            return path
        }
        
        // For development: try finding in project directory
        let projectPath = "/Users/markofucek/Desktop/GLTF-Studio/GLTFStudio/Resources/Binaries/gltfpack"
        if ProcessRunner.executableExists(at: projectPath) {
            return projectPath
        }
        
        return nil
    }
    
    /// Verify gltfpack is available and working
    func verifyGltfpack() async throws {
        guard let gltfpackPath = getGltfpackPath() else {
            throw ProcessingError.gltfpackNotFound
        }
        
        guard ProcessRunner.executableExists(at: gltfpackPath) else {
            throw ProcessingError.gltfpackNotFound
        }
        
        // Try running with --help to verify it works
        do {
            let output = try await processRunner.run(
                executablePath: gltfpackPath,
                arguments: ["--help"]
            )
            
            // gltfpack returns non-zero for --help, but that's okay
            // We just want to make sure it runs
            if output.combinedOutput.isEmpty {
                throw ProcessingError.gltfpackExecutionFailed(output: "gltfpack binary exists but doesn't respond")
            }
        } catch {
            throw ProcessingError.gltfpackExecutionFailed(output: "Failed to execute gltfpack: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Optimization
    
    /// Optimize a glTF/GLB file using gltfpack
    /// - Parameters:
    ///   - inputURL: URL to input glTF/GLB file
    ///   - outputURL: URL for output file
    ///   - config: Optimization configuration
    ///   - progressHandler: Optional callback for progress updates
    /// - Returns: Statistics about the optimization
    func optimize(
        inputURL: URL,
        outputURL: URL,
        config: OptimizationConfig,
        progressHandler: ((String) -> Void)? = nil
    ) async throws -> GLTFStats {
        
        print("🔍 [GLTFPACK] Verifying gltfpack binary...")
        
        // Verify gltfpack exists
        guard let gltfpackPath = getGltfpackPath() else {
            print("❌ [GLTFPACK] Binary not found!")
            throw ProcessingError.gltfpackNotFound
        }
        
        print("✅ [GLTFPACK] Found at: \(gltfpackPath)")
        
        // Parse glTF to detect features
        var hasAnimations = false
        var modelInfo: String = ""
        
        do {
            let info = try await gltfParser.parseFile(at: inputURL)
            hasAnimations = info.hasAnimations
            modelInfo = try await gltfParser.getSummary(for: inputURL)
            print("📊 [GLTFPACK] Model info: \(modelInfo)")
            
            if hasAnimations {
                print("🎬 [GLTFPACK] Animations detected - preserving skin weights")
            }
        } catch {
            print("⚠️ [GLTFPACK] Failed to parse glTF: \(error.localizedDescription)")
        }
        
        // Prepare stats
        var stats = GLTFStats(inputPath: inputURL.path, outputPath: outputURL.path)
        stats.startProcessing()
        
        // Build command arguments with animation awareness
        let arguments = config.buildGltfpackArguments(
            inputPath: inputURL.path,
            outputPath: outputURL.path
        )
        
        // Note: -si flag removed - not supported in current gltfpack version
        // Animation detection still logged for informational purposes
        
        // Log command for debugging
        let command = ([gltfpackPath] + arguments).joined(separator: " ")
        print("🔧 [GLTFPACK] Command: \(command)")
        
        // Use /tmp for temporary files (guaranteed writable)
        let tmpDir = FileManager.default.temporaryDirectory
        var environment = ProcessInfo.processInfo.environment
        environment["TMPDIR"] = tmpDir.path
        
        // Set working directory to output directory
        let workingDir = outputURL.deletingLastPathComponent().path
        
        print("📁 [GLTFPACK] Working dir: \(workingDir)")
        print("📁 [GLTFPACK] Temp dir: \(tmpDir.path)")
        
        // Execute gltfpack
        let output: ProcessRunner.ProcessOutput
        
        if let handler = progressHandler {
            output = try await processRunner.runWithStreaming(
                executablePath: gltfpackPath,
                arguments: arguments,
                workingDirectory: workingDir,
                environment: environment,
                outputHandler: handler
            )
        } else {
            output = try await processRunner.run(
                executablePath: gltfpackPath,
                arguments: arguments,
                workingDirectory: workingDir,
                environment: environment
            )
        }
        
        print("📤 [GLTFPACK] Exit code: \(output.exitCode)")
        
        // Check for errors
        guard output.success else {
            let errorMessage = output.stderr.isEmpty ? output.stdout : output.stderr
            print("❌ [GLTFPACK] Failed:\n\(errorMessage)")
            throw ProcessingError.gltfpackExecutionFailed(output: errorMessage)
        }
        
        // Verify output file was created
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            print("❌ [GLTFPACK] Output file not created!")
            throw ProcessingError.gltfpackExecutionFailed(output: "Output file was not created")
        }
        
        print("✅ [GLTFPACK] Output file created successfully")
        
        // Parse output for statistics
        stats.parseGltfpackOutput(output.combinedOutput)
        stats.finishProcessing()
        
        return stats
    }
    
    // MARK: - Batch Processing
    
    /// Optimize multiple files in sequence
    /// - Parameters:
    ///   - files: Array of (input, output) URL tuples
    ///   - config: Optimization configuration to use for all files
    ///   - progressHandler: Optional callback for progress updates
    /// - Returns: Array of statistics for each file
    func batchOptimize(
        files: [(input: URL, output: URL)],
        config: OptimizationConfig,
        progressHandler: ((Int, Int, String) -> Void)? = nil
    ) async throws -> [GLTFStats] {
        
        var allStats: [GLTFStats] = []
        
        for (index, filePair) in files.enumerated() {
            progressHandler?(index + 1, files.count, filePair.input.lastPathComponent)
            
            let stats = try await optimize(
                inputURL: filePair.input,
                outputURL: filePair.output,
                config: config
            )
            
            allStats.append(stats)
        }
        
        return allStats
    }
    
    // MARK: - Info & Version
    
    /// Get gltfpack version information
    func getVersion() async -> String? {
        guard let gltfpackPath = getGltfpackPath() else {
            return nil
        }
        
        do {
            let output = try await processRunner.run(
                executablePath: gltfpackPath,
                arguments: ["--version"]
            )
            
            return output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
    
    /// Get information about gltfpack binary
    func getInfo() async -> String {
        guard let gltfpackPath = getGltfpackPath() else {
            return "gltfpack not found"
        }
        
        var info = "gltfpack path: \(gltfpackPath)\n"
        
        // Check if executable
        if ProcessRunner.executableExists(at: gltfpackPath) {
            info += "Status: Executable ✓\n"
        } else {
            info += "Status: Not executable ✗\n"
        }
        
        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: gltfpackPath),
           let size = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            info += "Size: \(formatter.string(fromByteCount: size))\n"
        }
        
        // Get version
        if let version = await getVersion() {
            info += "Version: \(version)\n"
        }
        
        return info
    }
}

