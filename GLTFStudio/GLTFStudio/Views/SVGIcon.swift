//
//  SVGIcon.swift
//  GLTFStudio
//
//  Created on 2025-11-09.
//

import SwiftUI
import AppKit

struct SVGIcon: View {
    let name: String
    let size: CGFloat
    let color: Color
    
    var body: some View {
        // Try to load PNG from Resources/Icons
        let imagePath = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Icons") ??
                        Bundle.main.path(forResource: name, ofType: "png")
        
        if let path = imagePath,
           let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .aspectRatio(contentMode: .fit)
        } else {
            // Fallback to SF Symbol
            Image(systemName: "cube.fill")
                .resizable()
                .foregroundStyle(color)
                .frame(width: size, height: size)
        }
    }
}

// Simple wrapper za direktan pristup SVG-ovima
struct PointySwordIcon: View {
    var size: CGFloat = 40
    var color: Color = .primary
    
    var body: some View {
        SVGIcon(name: "pointy-sword", size: size, color: color)
    }
}

struct SwordSpinIcon: View {
    var size: CGFloat = 20
    var color: Color = .primary
    
    var body: some View {
        SVGIcon(name: "sword-spin", size: size, color: color)
    }
}

