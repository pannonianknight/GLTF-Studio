//
//  FilePickerView.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false
    
    private let fileService = FileService()
    
    var body: some View {
        VStack(spacing: 16) {
            // Input File Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Input File", systemImage: "doc.fill")
                        .font(.headline)
                    
                    if let inputURL = appState.inputFileURL {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(inputURL.lastPathComponent)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Text(inputURL.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Button(action: { appState.inputFileURL = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                    } else {
                        // Drop Zone
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 2, dash: [8])
                                )
                                .foregroundColor(isTargeted ? .accentColor : .secondary)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 32))
                                    .foregroundColor(isTargeted ? .accentColor : .secondary)
                                
                                Text("Drop GLB/GLTF file here")
                                    .font(.headline)
                                
                                Text("or")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("Choose File...") {
                                    selectInputFile()
                                }
                            }
                            .padding()
                        }
                        .frame(height: 120)
                        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                            handleDrop(providers: providers)
                        }
                    }
                }
                .padding(8)
            }
            
            // Output File Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Output File", systemImage: "doc.badge.gearshape.fill")
                        .font(.headline)
                    
                    if let outputURL = appState.outputFileURL {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(outputURL.lastPathComponent)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Text(outputURL.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Button("Change...") {
                                selectOutputFile()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                    } else {
                        Text("Output location will be auto-generated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                .padding(8)
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
    
    private func selectOutputFile() {
        Task {
            var suggestedFilename: String?
            if let inputURL = appState.inputFileURL {
                suggestedFilename = await fileService.suggestedOutputFilename(for: inputURL)
            }
            
            if let url = await fileService.presentSaveDialog(
                suggestedFilename: suggestedFilename,
                allowedFileTypes: ["glb", "gltf"]
            ) {
                await MainActor.run {
                    appState.selectOutputFile(url)
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

