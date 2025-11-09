//
//  TextureOptionsView.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI

struct TextureOptionsView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var textureEnabled: Bool = true
    @State private var textureFormat: TextureFormat = .etc1s
    @State private var textureQuality: Double = 128
    @State private var maxDimension: Int = 2048
    @State private var powerOfTwo: Bool = true
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Texture Optimization", systemImage: "photo.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    Toggle("Enabled", isOn: $textureEnabled)
                        .onChange(of: textureEnabled) { _, newValue in
                            updateConfig()
                        }
                }
                
                if textureEnabled {
                    VStack(alignment: .leading, spacing: 16) {
                        // Format Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Format")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Format", selection: $textureFormat) {
                                ForEach(TextureFormat.allCases, id: \.self) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: textureFormat) { _, _ in
                                updateConfig()
                            }
                            
                            formatDescription
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if textureFormat != .none {
                            Divider()
                            
                            // Quality Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Quality")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(textureQuality))")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $textureQuality, in: 1...255)
                                    .onChange(of: textureQuality) { _, newValue in
                                        textureQuality = round(newValue)
                                        updateConfig()
                                    }
                                
                                HStack {
                                    Text("Low")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("High")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // Max Dimension
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Max Dimension")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Picker("Max Dimension", selection: $maxDimension) {
                                    Text("256px").tag(256)
                                    Text("512px").tag(512)
                                    Text("1024px").tag(1024)
                                    Text("2048px").tag(2048)
                                    Text("4096px").tag(4096)
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: maxDimension) { _, _ in
                                    updateConfig()
                                }
                                
                                Text("Textures larger than this will be downscaled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            // Power of Two Toggle
                            Toggle("Force Power-of-Two Dimensions", isOn: $powerOfTwo)
                                .onChange(of: powerOfTwo) { _, _ in
                                    updateConfig()
                                }
                            
                            Text("Required for compatibility with older GPUs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(8)
        }
        .onAppear {
            loadConfigValues()
        }
        .onChange(of: appState.config) { _, _ in
            loadConfigValues()
        }
    }
    
    @ViewBuilder
    private var formatDescription: some View {
        switch textureFormat {
        case .etc1s:
            Text("ETC1S: Best compression ratio, good quality. Recommended for mobile.")
        case .uastc:
            Text("UASTC: Higher quality, larger files. For high-end devices.")
        case .none:
            Text("No compression: Keep original textures unchanged.")
        }
    }
    
    private func loadConfigValues() {
        textureEnabled = appState.config.texture.enabled
        textureFormat = appState.config.texture.format
        textureQuality = Double(appState.config.texture.quality)
        maxDimension = appState.config.texture.maxDimension
        powerOfTwo = appState.config.texture.powerOfTwo
    }
    
    private func updateConfig() {
        var newConfig = appState.config
        newConfig.texture.enabled = textureEnabled
        newConfig.texture.format = textureFormat
        newConfig.texture.quality = Int(textureQuality)
        newConfig.texture.maxDimension = maxDimension
        newConfig.texture.powerOfTwo = powerOfTwo
        appState.updateCustomConfig(newConfig)
    }
}

#Preview {
    TextureOptionsView()
        .environmentObject(AppState())
        .frame(width: 500)
        .padding()
}

