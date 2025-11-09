//
//  GLTFStudioApp.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI

@main
struct GLTFStudioApp: App {
    
    init() {
        print("🚀 [APP] GLTFStudio launching...")
        print("📍 [APP] Bundle path: \(Bundle.main.bundlePath)")
        print("🔧 [APP] macOS version: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button("Open glTF/GLB...") {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            // Help Menu
            CommandGroup(replacing: .help) {
                Button("GLTFStudio Help") {
                    openDocumentation()
                }
                
                Button("Report Issue") {
                    reportIssue()
                }
                
                Divider()
                
                Button("About gltfpack") {
                    showAboutGltfpack()
                }
            }
        }
    }
    
    // MARK: - Menu Actions
    
    private func openFile() {
        // This will be handled by the ContentView
        // Could use NotificationCenter or other mechanism to communicate
    }
    
    private func openDocumentation() {
        if let url = URL(string: "https://github.com/yourusername/GLTFStudio/blob/main/README.md") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func reportIssue() {
        if let url = URL(string: "https://github.com/yourusername/GLTFStudio/issues/new") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showAboutGltfpack() {
        if let url = URL(string: "https://github.com/zeux/meshoptimizer/tree/master/gltf") {
            NSWorkspace.shared.open(url)
        }
    }
}

