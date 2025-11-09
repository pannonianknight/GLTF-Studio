//
//  ProcessRunner.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import Foundation

/// Generic CLI process runner with async/await support
actor ProcessRunner {
    
    // MARK: - Output Handling
    
    struct ProcessOutput {
        let stdout: String
        let stderr: String
        let exitCode: Int32
        
        var success: Bool {
            return exitCode == 0
        }
        
        var combinedOutput: String {
            var output = ""
            if !stdout.isEmpty {
                output += stdout
            }
            if !stderr.isEmpty {
                if !output.isEmpty {
                    output += "\n"
                }
                output += stderr
            }
            return output
        }
    }
    
    // MARK: - Execution
    
    /// Run a command-line process asynchronously
    /// - Parameters:
    ///   - executablePath: Full path to the executable
    ///   - arguments: Command-line arguments
    ///   - workingDirectory: Working directory (defaults to temporary directory)
    ///   - environment: Environment variables (defaults to current environment)
    /// - Returns: ProcessOutput with stdout, stderr, and exit code
    func run(
        executablePath: String,
        arguments: [String],
        workingDirectory: String? = nil,
        environment: [String: String]? = nil
    ) async throws -> ProcessOutput {
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            
            // Setup executable
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            
            // Setup working directory
            if let workingDir = workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            }
            
            // Setup environment
            if let env = environment {
                process.environment = env
            }
            
            // Setup pipes for output
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            // Termination handler - read all at once to avoid concurrency issues
            process.terminationHandler = { process in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                
                let output = ProcessOutput(
                    stdout: stdout,
                    stderr: stderr,
                    exitCode: process.terminationStatus
                )
                
                continuation.resume(returning: output)
            }
            
            // Launch process
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Streaming Execution
    
    /// Run a command with streaming output callback
    /// - Parameters:
    ///   - executablePath: Full path to the executable
    ///   - arguments: Command-line arguments
    ///   - workingDirectory: Working directory
    ///   - environment: Environment variables
    ///   - outputHandler: Callback for streaming output (called on background thread)
    /// - Returns: ProcessOutput with complete stdout, stderr, and exit code
    func runWithStreaming(
        executablePath: String,
        arguments: [String],
        workingDirectory: String? = nil,
        environment: [String: String]? = nil,
        outputHandler: @escaping (String) -> Void
    ) async throws -> ProcessOutput {
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            
            if let workingDir = workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            }
            
            if let env = environment {
                process.environment = env
            }
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            // Termination handler - streaming version
            let outputQueue = DispatchQueue(label: "com.gltfstudio.streaming")
            
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                    outputQueue.async {
                        outputHandler(line)
                    }
                }
            }
            
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                    outputQueue.async {
                        outputHandler(line)
                    }
                }
            }
            
            process.terminationHandler = { process in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                
                let output = ProcessOutput(
                    stdout: stdout,
                    stderr: stderr,
                    exitCode: process.terminationStatus
                )
                
                continuation.resume(returning: output)
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if an executable exists at the given path
    static func executableExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        
        guard exists && !isDirectory.boolValue else {
            return false
        }
        
        // Check if file is executable
        return FileManager.default.isExecutableFile(atPath: path)
    }
    
    /// Find executable in system PATH
    static func findExecutable(named name: String) async -> String? {
        let processRunner = ProcessRunner()
        
        do {
            let output = try await processRunner.run(
                executablePath: "/usr/bin/which",
                arguments: [name]
            )
            
            if output.success {
                return output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return nil
        }
        
        return nil
    }
}

