//
//  MeshOptionsView.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI

struct MeshOptionsView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var meshCompression: Bool = true
    @State private var vertexPosition: Double = 14
    @State private var vertexTexCoord: Double = 12
    @State private var vertexNormal: Double = 10
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Mesh Optimization", systemImage: "cube.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    Toggle("Compression", isOn: $meshCompression)
                        .onChange(of: meshCompression) { _, _ in
                            updateConfig()
                        }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Vertex Position Bits
                    quantizationSlider(
                        title: "Vertex Position",
                        value: $vertexPosition,
                        description: "Position precision (higher = better quality)"
                    )
                    
                    Divider()
                    
                    // Texture Coordinates Bits
                    quantizationSlider(
                        title: "Texture Coordinates",
                        value: $vertexTexCoord,
                        description: "UV mapping precision"
                    )
                    
                    Divider()
                    
                    // Normals Bits
                    quantizationSlider(
                        title: "Normals",
                        value: $vertexNormal,
                        description: "Normal vector precision"
                    )
                }
                
                // Info Box
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("Higher bit counts preserve more detail but result in larger files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
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
    private func quantizationSlider(
        title: String,
        value: Binding<Double>,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(value.wrappedValue)) bits")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: value, in: 8...16, step: 1)
                .onChange(of: value.wrappedValue) { _, _ in
                    updateConfig()
                }
            
            HStack {
                Text("8")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("12")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("16")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func loadConfigValues() {
        meshCompression = appState.config.mesh.compression
        vertexPosition = Double(appState.config.mesh.vertexPosition)
        vertexTexCoord = Double(appState.config.mesh.vertexTexCoord)
        vertexNormal = Double(appState.config.mesh.vertexNormal)
    }
    
    private func updateConfig() {
        var newConfig = appState.config
        newConfig.mesh.compression = meshCompression
        newConfig.mesh.vertexPosition = Int(vertexPosition)
        newConfig.mesh.vertexTexCoord = Int(vertexTexCoord)
        newConfig.mesh.vertexNormal = Int(vertexNormal)
        appState.updateCustomConfig(newConfig)
    }
}

#Preview {
    MeshOptionsView()
        .environmentObject(AppState())
        .frame(width: 500)
        .padding()
}

