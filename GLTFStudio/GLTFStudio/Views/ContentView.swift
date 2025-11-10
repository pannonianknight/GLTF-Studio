//
//  ContentView.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var appState = AppState()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var logOutput: String = "Ready to optimize..."
    
    private let gltfPackService = GLTFPackService()
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT PANEL - Input/Output/Action
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                    
                    Text("GLTF Studio v1.0")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text("gltf/glb optimisation tool")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                // File Selection (always visible)
                FilePickerView()
                    .environmentObject(appState)
                
                Spacer()
                
                // Process Button (sticky to bottom)
                processButton
                    .padding(.bottom, 20)
                
                // Copyright
                Text("Marko Fuček © 2025")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .frame(width: 320)
            .padding(.horizontal, 20)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // RIGHT PANEL - Settings & Log
            VStack(spacing: 0) {
                // Preset Tabs
                Picker("", selection: $appState.selectedPreset) {
                    Text("Low Quality").tag(OptimizationPreset.low)
                    Text("Balanced").tag(OptimizationPreset.balanced)
                    Text("High Quality").tag(OptimizationPreset.high)
                    Text("Custom").tag(OptimizationPreset.custom)
                }
                .pickerStyle(.segmented)
                .padding(16)
                .onChange(of: appState.selectedPreset) { _, newValue in
                    appState.selectPreset(newValue)
                    appendLog("Preset changed to: \(newValue.displayName)")
                }
                
                Divider()
                
                // Settings Area (Scrollable)
                ScrollView {
                    VStack(spacing: 16) {
                        // Show preset description OR full settings
                        if appState.selectedPreset == .custom {
                            // Custom: Show full settings
                            TextureOptionsView()
                                .environmentObject(appState)
                            
                            MeshOptionsView()
                                .environmentObject(appState)
                        } else {
                            // Low/Balanced/High: Show description
                            presetDescriptionView
                        }
                    }
                    .padding(16)
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
                
                // Log & Stats Area (side by side)
                HStack(spacing: 16) {
                    // Log Area (1/3)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Log")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if appState.processingState.isProcessing {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.7)
                            }
                        }
                        
                        ScrollViewReader { proxy in
                            ScrollView {
                                Text(logOutput)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .padding(8)
                                    .id("logEnd")
                            }
                            .frame(height: 120)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(6)
                            .onChange(of: logOutput) { _, _ in
                                proxy.scrollTo("logEnd", anchor: .bottom)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Stats Area (2/3)
                    if appState.processingState.isCompleted, let stats = appState.processingState.stats {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            compactStatsView(stats)
                        }
                        .frame(maxWidth: .infinity * 2)
                    }
                }
                .padding(16)
                
                Divider()
                
                // Bottom Buttons
                HStack {
                    Button("3D Preview") {
                        appendLog("3D Preview coming soon...")
                    }
                    .disabled(true)
                    
                    Spacer()
                    
                    Button("Help") {
                        if let url = URL(string: "https://github.com/pannonianknight/GLTF-Studio") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                }
                .padding(16)
            }
            .frame(minWidth: 400)
        }
        .frame(minWidth: 720, idealWidth: 900, maxWidth: .infinity,
               minHeight: 600, idealHeight: 700, maxHeight: .infinity)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                appState.resetProcessing()
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: appState.processingState) { _, newState in
            if case .failed(let error) = newState {
                errorMessage = error.localizedDescription
                showError = true
                appendLog("❌ Error: \(error.localizedDescription)")
            }
        }
        .onAppear {
            appendLog("✨ GLTFStudio v1.0 ready")
        }
        .onChange(of: appState.inputFileURL) { _, newValue in
            if newValue != nil {
                // Reset when new file is selected
                if appState.processingState.isCompleted {
                    appState.resetProcessing()
                    logOutput = "Ready to optimize..."
                }
                appendLog("📁 File selected: \(newValue?.lastPathComponent ?? "")")
            } else {
                // File cleared
                if appState.processingState.isCompleted {
                    appState.resetProcessing()
                    logOutput = "Ready to optimize..."
                }
            }
        }
    }
    
    @ViewBuilder
    private var presetDescriptionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch appState.selectedPreset {
            case .low:
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.orange)
                        Text("Low Quality")
                            .font(.headline)
                    }
                    
                    Text("Maximum Compression")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Best for low-end mobile devices. Aggressive optimization with visible quality loss. Reduces file size to ~10-20% of original.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        settingRow(label: "Texture Quality", value: "1 (Lowest)")
                        settingRow(label: "Texture Size", value: "1024px max")
                        settingRow(label: "Vertex Position", value: "12 bits")
                        settingRow(label: "Texture Coords", value: "10 bits")
                        settingRow(label: "Normals", value: "8 bits")
                    }
                    .font(.caption)
                }
                
            case .balanced:
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "scale.3d")
                            .foregroundColor(.blue)
                        Text("Balanced")
                            .font(.headline)
                    }
                    
                    Text("Recommended")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("General mobile and web use. Good balance between size and quality. Reduces file size to ~30-40% of original.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        settingRow(label: "Texture Quality", value: "128 (Medium)")
                        settingRow(label: "Texture Size", value: "2048px max")
                        settingRow(label: "Vertex Position", value: "14 bits")
                        settingRow(label: "Texture Coords", value: "12 bits")
                        settingRow(label: "Normals", value: "10 bits")
                    }
                    .font(.caption)
                }
                
            case .high:
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("High Quality")
                            .font(.headline)
                    }
                    
                    Text("Maximum Quality")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("For desktop and high-end mobile devices. Minimal quality loss with moderate compression. Reduces file size to ~50-70% of original.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        settingRow(label: "Texture Format", value: "UASTC (High Quality)")
                        settingRow(label: "Texture Quality", value: "10 (High)")
                        settingRow(label: "Texture Size", value: "4096px max")
                        settingRow(label: "Vertex Position", value: "16 bits")
                        settingRow(label: "Texture Coords", value: "14 bits")
                        settingRow(label: "Normals", value: "12 bits")
                    }
                    .font(.caption)
                }
                
            case .custom:
                EmptyView()
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func settingRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private var processButton: some View {
        Button(action: {
            Task {
                await optimize()
            }
        }) {
            HStack {
                if appState.processingState.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .progressViewStyle(.circular)
                } else {
                    Image("PointySword")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 18, height: 18)
                }
                
                Text(appState.processingState.isProcessing ? "Optimizing..." : "Optimize")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!canOptimize)
    }
    
    private var canOptimize: Bool {
        return appState.inputFileURL != nil &&
               appState.outputFileURL != nil &&
               !appState.processingState.isProcessing
    }
    
    // MARK: - Optimization
    
    @MainActor
    private func optimize() async {
        appendLog("🚀 Starting optimization...")
        
        // Check if any optimization is enabled
        let textureEnabled = appState.config.texture.enabled
        let meshEnabled = appState.config.mesh.compression || 
                         appState.config.mesh.vertexPosition < 16 ||
                         appState.config.mesh.vertexTexCoord < 16 ||
                         appState.config.mesh.vertexNormal < 16
        
        if !textureEnabled && !meshEnabled {
            appendLog("⚠️ No compression enabled - file will be copied without optimization")
        }
        
        // Validate inputs
        let validation = appState.validateInputs()
        switch validation {
        case .success:
            appendLog("✅ Validation passed")
            break
        case .failure(let error):
            appendLog("❌ Validation failed: \(error.localizedDescription)")
            appState.failProcessing(error: error)
            return
        }
        
        guard let inputURL = appState.inputFileURL,
              let outputURL = appState.outputFileURL else {
            appState.failProcessing(error: .invalidFile(reason: "Missing input or output file"))
            return
        }
        
        appendLog("📂 Input: \(inputURL.lastPathComponent)")
        appendLog("📂 Output: \(outputURL.lastPathComponent)")
        appendLog("⚙️ Preset: \(appState.config.preset.displayName)")
        appendLog("🔍 Analyzing model...")
        
        if textureEnabled {
            appendLog("🎨 Texture: \(appState.config.texture.format.rawValue), Quality: \(appState.config.texture.quality)")
        }
        if meshEnabled {
            appendLog("📦 Mesh: Compression=\(appState.config.mesh.compression), VP=\(appState.config.mesh.vertexPosition)bit")
        }
        
        // Start processing
        appState.startProcessing()
        
        do {
            // Run optimization
            appendLog("🔧 Running gltfpack...")
            let stats = try await gltfPackService.optimize(
                inputURL: inputURL,
                outputURL: outputURL,
                config: appState.config,
                progressHandler: { output in
                    if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        appendLog(output.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            )
            
            appendLog("✅ Optimization complete!")
            appendLog("💾 Saved: \(stats.sizeSavedFormatted) (\(stats.compressionRatioFormatted))")
            
            // Update state with results
            await MainActor.run {
                appState.completeProcessing(stats: stats)
            }
            
        } catch let error as ProcessingError {
            await MainActor.run {
                appState.failProcessing(error: error)
            }
        } catch {
            await MainActor.run {
                appState.failProcessing(error: .unknown(message: error.localizedDescription))
            }
        }
    }
    
    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logOutput += "\n[\(timestamp)] \(message)"
    }
    
    
    @ViewBuilder
    private func compactStatsView(_ stats: GLTFStats) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                statBadge(icon: "arrow.down.circle.fill", label: "Input", value: stats.inputSizeFormatted, color: .blue)
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                statBadge(icon: "checkmark.circle.fill", label: "Output", value: stats.outputSizeFormatted, color: .green)
            }
            
            HStack(spacing: 12) {
                statBadge(icon: "chart.bar.fill", label: "Saved", value: stats.compressionRatioFormatted, color: .orange)
                statBadge(icon: "clock.fill", label: "Time", value: stats.processingTimeFormatted, color: .purple)
            }
            
            if let outputPath = stats.outputPath, FileManager.default.fileExists(atPath: outputPath) {
                Button(action: {
                    let url = URL(fileURLWithPath: outputPath)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }) {
                    Label("Show in Finder", systemImage: "folder.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }
    
    private func statBadge(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    ContentView()
}

