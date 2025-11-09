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
    
    private let gltfPackService = GLTFPackService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "cube.transparent.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("GLTF Studio")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("Professional glTF/GLB Optimization")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // File Selection
                FilePickerView()
                    .environmentObject(appState)
                
                // Preset Selection
                PresetSelectorView()
                    .environmentObject(appState)
                
                // Options (only show for custom preset or when custom changes are made)
                if appState.selectedPreset == .custom {
                    VStack(spacing: 16) {
                        TextureOptionsView()
                            .environmentObject(appState)
                        
                        MeshOptionsView()
                            .environmentObject(appState)
                    }
                }
                
                // Process Button
                processButton
                
                // Progress Indicator
                if appState.processingState.isProcessing {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .padding(.horizontal)
                }
                
                // Stats Display
                if appState.processingState.isCompleted {
                    StatsView()
                        .environmentObject(appState)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(20)
        }
        .frame(minWidth: 500, idealWidth: 550, maxWidth: 600,
               minHeight: 700, idealHeight: 800, maxHeight: .infinity)
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
            }
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
                    Image(systemName: "gearshape.fill")
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
        print("🚀 [OPTIMIZE] Starting optimization...")
        
        // Validate inputs
        let validation = appState.validateInputs()
        switch validation {
        case .success:
            print("✅ [OPTIMIZE] Validation passed")
            break
        case .failure(let error):
            print("❌ [OPTIMIZE] Validation failed: \(error)")
            appState.failProcessing(error: error)
            return
        }
        
        guard let inputURL = appState.inputFileURL,
              let outputURL = appState.outputFileURL else {
            print("❌ [OPTIMIZE] Missing input or output URL")
            appState.failProcessing(error: .invalidFile(reason: "Missing input or output file"))
            return
        }
        
        print("📂 [OPTIMIZE] Input: \(inputURL.path)")
        print("📂 [OPTIMIZE] Output: \(outputURL.path)")
        print("⚙️  [OPTIMIZE] Config: \(appState.config.preset.rawValue)")
        
        // Start processing
        appState.startProcessing()
        
        do {
            // Run optimization
            print("🔧 [OPTIMIZE] Calling gltfpack...")
            let stats = try await gltfPackService.optimize(
                inputURL: inputURL,
                outputURL: outputURL,
                config: appState.config,
                progressHandler: { output in
                    print("📝 [GLTFPACK] \(output)")
                }
            )
            
            print("✅ [OPTIMIZE] Success! Saved \(stats.sizeSavedFormatted)")
            
            // Update state with results
            await MainActor.run {
                appState.completeProcessing(stats: stats)
            }
            
        } catch let error as ProcessingError {
            print("❌ [OPTIMIZE] ProcessingError: \(error)")
            await MainActor.run {
                appState.failProcessing(error: error)
            }
        } catch {
            print("❌ [OPTIMIZE] Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                appState.failProcessing(error: .unknown(message: error.localizedDescription))
            }
        }
    }
}

#Preview {
    ContentView()
}

