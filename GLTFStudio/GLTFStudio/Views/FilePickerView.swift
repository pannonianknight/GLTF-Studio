//
//  FilePickerView.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct FilePickerView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false
    
    private let fileService = FileService()
    
    var body: some View {
        VStack(spacing: 20) {
            // Drop Zone - Dynamic content (FIXED HEIGHT)
            Group {
                if let inputURL = appState.inputFileURL {
                    // FILE SELECTED - Show file info INSIDE drop zone
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(inputURL.lastPathComponent)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .lineLimit(3)
                                .truncationMode(.middle)
                        }
                        
                        Spacer()
                        
                        Button(action: { 
                            appState.inputFileURL = nil
                            appState.outputFileURL = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Clear selection")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                        handleDrop(providers: providers)
                    }
                } else {
                    // NO FILE - Show drop zone
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 40))
                            .foregroundColor(isTargeted ? .accentColor : .secondary)
                        
                        Text("Drop GLB/GLTF")
                            .font(.headline)
                        
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Choose File") {
                            selectInputFile()
                        }
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(isTargeted ? 0.8 : 0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTargeted ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                        handleDrop(providers: providers)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: appState.inputFileURL != nil)
            
            Spacer()
            
            // Output folder selection (iznad Optimize button-a)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Output Folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Choose...") {
                        selectOutputFolder()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
                
                if let outputURL = appState.outputFileURL {
                    Text(outputURL.deletingLastPathComponent().path)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Same as input file")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectInputFile() {
        Task {
            if let urls = await fileService.presentOpenDialog(
                allowedFileTypes: ["glb", "gltf"],
                allowsMultipleSelection: false
            ), let url = urls.first {
                await MainActor.run {
                    appState.selectInputFile(url)
                }
            }
        }
    }
    
    private func selectOutputFolder() {
        Task {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.allowsMultipleSelection = false
            panel.message = "Choose output folder for optimized files"
            
            let response = await MainActor.run { panel.runModal() }
            
            if response == .OK, let folderURL = panel.url, let inputURL = appState.inputFileURL {
                let outputFilename = await fileService.suggestedOutputFilename(for: inputURL)
                let outputURL = folderURL.appendingPathComponent(outputFilename)
                
                await MainActor.run {
                    appState.selectOutputFile(outputURL)
                    print("📁 [FILEPICKER] Output folder: \(folderURL.path)")
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        print("🎯 [DROP] File dropped")
        guard let provider = providers.first else { 
            print("❌ [DROP] No provider")
            return false 
        }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                print("❌ [DROP] Failed to get URL")
                return
            }
            
            print("📂 [DROP] File: \(url.lastPathComponent)")
            
            Task {
                let valid = await fileService.isValidGLTFFile(at: url)
                
                if valid {
                    print("✅ [DROP] Valid glTF file")
                    await MainActor.run {
                        appState.selectInputFile(url)
                    }
                } else {
                    print("❌ [DROP] Invalid file type")
                }
            }
        }
        
        return true
    }
}

#Preview {
    FilePickerView()
        .environmentObject(AppState())
        .frame(width: 500)
        .padding()
}

