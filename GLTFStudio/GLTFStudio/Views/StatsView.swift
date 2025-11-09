//
//  StatsView.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI

struct StatsView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Statistics", systemImage: "chart.bar.fill")
                    .font(.headline)
                
                if let stats = appState.processingState.stats {
                    statsContent(stats)
                } else {
                    emptyState
                }
            }
            .padding(8)
        }
    }
    
    @ViewBuilder
    private func statsContent(_ stats: GLTFStats) -> some View {
        VStack(spacing: 12) {
            // File Size Comparison
            HStack(spacing: 16) {
                statItem(
                    title: "Input Size",
                    value: stats.inputSizeFormatted,
                    icon: "doc.fill",
                    color: .blue
                )
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                statItem(
                    title: "Output Size",
                    value: stats.outputSizeFormatted,
                    icon: "doc.badge.gearshape.fill",
                    color: .green
                )
            }
            
            Divider()
            
            // Compression Stats
            HStack(spacing: 16) {
                statItem(
                    title: "Space Saved",
                    value: stats.sizeSavedFormatted,
                    icon: "arrow.down.circle.fill",
                    color: .orange
                )
                
                statItem(
                    title: "Compression",
                    value: stats.compressionRatioFormatted,
                    icon: "gauge.high",
                    color: .purple
                )
            }
            
            Divider()
            
            // Model Info
            if stats.vertexCount != nil || stats.triangleCount != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Information")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let vertices = stats.vertexCount {
                        infoRow(label: "Vertices", value: "\(vertices)")
                    }
                    
                    if let triangles = stats.triangleCount {
                        infoRow(label: "Triangles", value: "\(triangles)")
                    }
                    
                    if let meshes = stats.meshCount {
                        infoRow(label: "Meshes", value: "\(meshes)")
                    }
                    
                    if let materials = stats.materialCount {
                        infoRow(label: "Materials", value: "\(materials)")
                    }
                    
                    if let textures = stats.textureCount {
                        infoRow(label: "Textures", value: "\(textures)")
                    }
                }
                
                Divider()
            }
            
            // Processing Time
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.secondary)
                Text("Processing Time:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(stats.processingTimeFormatted)
                    .fontWeight(.medium)
            }
            .font(.caption)
            
            // Reveal in Finder Button
            if let outputPath = stats.outputPath,
               FileManager.default.fileExists(atPath: outputPath) {
                Button(action: {
                    revealInFinder(path: outputPath)
                }) {
                    Label("Show in Finder", systemImage: "folder.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No statistics yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Run optimization to see results")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private func statItem(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
    
    private func revealInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

#Preview {
    VStack {
        // Preview with stats
        StatsView()
            .environmentObject({
                let state = AppState()
                var stats = GLTFStats(inputPath: "/test/input.glb", outputPath: "/test/output.glb")
                stats.inputSize = 10_000_000
                stats.outputSize = 3_500_000
                stats.processingTime = 4.32
                stats.vertexCount = 12_340
                stats.triangleCount = 8_910
                stats.meshCount = 5
                state.completeProcessing(stats: stats)
                return state
            }())
        
        // Preview without stats
        StatsView()
            .environmentObject(AppState())
    }
    .frame(width: 500)
    .padding()
}

