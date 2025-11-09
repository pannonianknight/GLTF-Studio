# Xcode Setup - GLTFStudio

## 1. Build gltfpack (5 min)

```bash
cd /Users/markofucek/Desktop/GLTF-Studio
./build_gltfpack.sh
```

Čekaj dok se završi build...

## 2. Xcode Projekt

### Kreiraj projekt
1. Otvori Xcode
2. File → New → Project (Cmd+Shift+N)
3. **macOS → App** → Next
4. Popuni:
   - Product Name: `GLTFStudio`
   - Interface: SwiftUI
   - Language: Swift
5. Save u: `/Users/markofucek/Desktop/GLTF-Studio/`

### Obriši default fajlove
- Desni klik na `ContentView.swift` → Delete → Move to Trash
- Desni klik na `GLTFStudioApp.swift` → Delete → Move to Trash

### Dodaj naše fajlove
1. Desni klik na `GLTFStudio` folder
2. **Add Files to "GLTFStudio"...**
3. Odaberi:
   - GLTFStudioApp.swift
   - Models folder
   - Services folder
   - Views folder
   - Resources folder
4. **Unchecked**: Copy items if needed
5. **Checked**: Add to targets: GLTFStudio
6. Add

## 3. Build Settings

1. Klikni plavi GLTFStudio projekt (top)
2. Target: GLTFStudio
3. **General**: Minimum Deployments → **macOS 13.0**
4. **Signing & Capabilities**: Odaberi Team
5. **Build Phases** → Copy Bundle Resources:
   - Mora biti tu: `gltfpack` (u Binaries)

## 4. Run

Cmd+R

Done! 🚀

