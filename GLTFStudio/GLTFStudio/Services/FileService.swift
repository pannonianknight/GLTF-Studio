//
//  FileService.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// Service for file I/O operations
actor FileService {
    
    // MARK: - File Validation
    
    /// Check if a file is a valid glTF or GLB file
    func isValidGLTFFile(at url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "gltf" || ext == "glb"
    }
    
    /// Get file size in bytes
    func getFileSize(at url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    // MARK: - File Operations
    
    /// Copy file from one location to another
    func copyFile(from source: URL, to destination: URL, overwrite: Bool = false) throws {
        let fileManager = FileManager.default
        
        // Remove destination if it exists and overwrite is enabled
        if overwrite && fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        
        try fileManager.copyItem(at: source, to: destination)
    }
    
    /// Move file from one location to another
    func moveFile(from source: URL, to destination: URL, overwrite: Bool = false) throws {
        let fileManager = FileManager.default
        
        // Remove destination if it exists and overwrite is enabled
        if overwrite && fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        
        try fileManager.moveItem(at: source, to: destination)
    }
    
    /// Delete file at URL
    func deleteFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    /// Check if file exists
    func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: - Temporary Files
    
    /// Create a temporary file URL with given extension
    func createTemporaryFileURL(withExtension ext: String) -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + "." + ext
        return temporaryDirectory.appendingPathComponent(filename)
    }
    
    /// Clean up temporary files older than specified time
    func cleanupTemporaryFiles(olderThan interval: TimeInterval = 3600) throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileManager = FileManager.default
        
        let contents = try fileManager.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        let cutoffDate = Date().addingTimeInterval(-interval)
        
        for fileURL in contents {
            guard fileURL.pathExtension == "glb" || fileURL.pathExtension == "gltf" else {
                continue
            }
            
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let creationDate = attributes[.creationDate] as? Date,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Directory Operations
    
    /// Create directory if it doesn't exist
    func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    // MARK: - File Dialogs
    
    /// Present file open dialog on main thread
    @MainActor
    func presentOpenDialog(
        allowedFileTypes: [String] = ["glb", "gltf"],
        allowsMultipleSelection: Bool = false
    ) async -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = allowedFileTypes.compactMap { ext in
            UTType(filenameExtension: ext)
        }
        
        let response = panel.runModal()
        
        if response == .OK {
            return panel.urls
        }
        
        return nil
    }
    
    /// Present file save dialog on main thread
    @MainActor
    func presentSaveDialog(
        suggestedFilename: String? = nil,
        allowedFileTypes: [String] = ["glb", "gltf"]
    ) async -> URL? {
        let panel = NSSavePanel()
        
        if let filename = suggestedFilename {
            panel.nameFieldStringValue = filename
        }
        
        panel.allowedContentTypes = allowedFileTypes.compactMap { ext in
            UTType(filenameExtension: ext)
        }
        
        let response = panel.runModal()
        
        if response == .OK {
            return panel.url
        }
        
        return nil
    }
    
    // MARK: - Reveal in Finder
    
    /// Show file in Finder
    @MainActor
    func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    // MARK: - Quick Look
    
    /// Open file in Quick Look (if possible)
    @MainActor
    func quickLook(url: URL) {
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Drag & Drop Support

extension FileService {
    
    /// Validate dropped URLs for glTF files
    func validateDroppedURLs(_ urls: [URL]) -> [URL] {
        return urls.filter { isValidGLTFFile(at: $0) }
    }
    
    /// Get suggested output filename for input file
    func suggestedOutputFilename(for inputURL: URL, suffix: String = "_optimized") -> String {
        let filename = inputURL.deletingPathExtension().lastPathComponent
        let ext = inputURL.pathExtension
        return "\(filename)\(suffix).\(ext)"
    }
    
    /// Get suggested output URL in same directory as input
    func suggestedOutputURL(for inputURL: URL, suffix: String = "_optimized") -> URL {
        let directory = inputURL.deletingLastPathComponent()
        let filename = suggestedOutputFilename(for: inputURL, suffix: suffix)
        return directory.appendingPathComponent(filename)
    }
}

