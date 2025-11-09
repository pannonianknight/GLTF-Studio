//
//  PresetSelectorView.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI

struct PresetSelectorView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Optimization Preset", systemImage: "slider.horizontal.3")
                    .font(.headline)
                
                Picker("Preset", selection: $appState.selectedPreset) {
                    ForEach(OptimizationPreset.allCases, id: \.self) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: appState.selectedPreset) { _, newValue in
                    appState.selectPreset(newValue)
                }
                
                // Preset Description
                presetDescription
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(8)
        }
    }
    
    @ViewBuilder
    private var presetDescription: some View {
        switch appState.selectedPreset {
        case .low:
            VStack(alignment: .leading, spacing: 4) {
                Text("⚡ Maximum Compression")
                    .fontWeight(.medium)
                Text("Best for low-end mobile devices. Aggressive optimization with visible quality loss. ~10-20% of original size.")
            }
            
        case .balanced:
            VStack(alignment: .leading, spacing: 4) {
                Text("⚖️ Balanced Quality")
                    .fontWeight(.medium)
                Text("Recommended for most mobile and web applications. Good balance between size and quality. ~30-40% of original size.")
            }
            
        case .high:
            VStack(alignment: .leading, spacing: 4) {
                Text("✨ High Quality")
                    .fontWeight(.medium)
                Text("For high-end devices and desktop. Minimal quality loss with moderate compression. ~50-70% of original size.")
            }
            
        case .custom:
            VStack(alignment: .leading, spacing: 4) {
                Text("🎛️ Custom Settings")
                    .fontWeight(.medium)
                Text("Fine-tune all optimization parameters manually using the controls below.")
            }
        }
    }
}

#Preview {
    PresetSelectorView()
        .environmentObject(AppState())
        .frame(width: 500)
        .padding()
}

