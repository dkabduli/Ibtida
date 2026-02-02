#!/usr/bin/env swift
//
//  GenerateAppIcon.swift
//  Run this script to generate the Ibtida app icon matching the Welcome page style.
//
//  Usage: swift GenerateAppIcon.swift
//  Output: Creates AppIcon-1024.png in the AppIcon.appiconset folder
//

import Foundation
import AppKit
import CoreGraphics

// MARK: - Colors (matching Welcome page in AppTheme.swift)

let warmCream = NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)  // #FAF5EB
let mutedGold = NSColor(red: 0.80, green: 0.68, blue: 0.42, alpha: 1.0)  // #CCAD6B
let deepGold = NSColor(red: 0.72, green: 0.58, blue: 0.30, alpha: 1.0)   // #B8944D

// MARK: - Icon Generation

func generateIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    // Background - warm cream fill
    warmCream.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    
    // Draw SF Symbol "hands.sparkles.fill" with gold gradient
    if let symbolImage = NSImage(systemSymbolName: "hands.sparkles.fill", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.45, weight: .medium)
        let configuredSymbol = symbolImage.withSymbolConfiguration(config) ?? symbolImage
        
        // Calculate centered position
        let symbolSize = configuredSymbol.size
        let x = (CGFloat(size) - symbolSize.width) / 2
        let y = (CGFloat(size) - symbolSize.height) / 2
        
        // Create gradient
        let gradient = NSGradient(colors: [mutedGold, deepGold])!
        
        // Draw symbol with gradient tint
        // First, draw the symbol to get its mask
        let symbolRect = NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height)
        
        // For SF Symbols, we need to use template rendering
        let templateSymbol = configuredSymbol.copy() as! NSImage
        templateSymbol.isTemplate = true
        
        // Draw with tint color (using the average of the gradient)
        let tintColor = NSColor(red: 0.76, green: 0.63, blue: 0.36, alpha: 1.0)
        
        // Create a colored version
        let coloredImage = NSImage(size: symbolSize)
        coloredImage.lockFocus()
        tintColor.set()
        templateSymbol.draw(in: NSRect(origin: .zero, size: symbolSize),
                           from: .zero,
                           operation: .sourceOver,
                           fraction: 1.0)
        // Apply tint
        NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
        coloredImage.unlockFocus()
        
        coloredImage.draw(in: symbolRect,
                         from: .zero,
                         operation: .sourceOver,
                         fraction: 1.0)
    }
    
    image.unlockFocus()
    return image
}

func saveImage(_ image: NSImage, to path: String) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Error: Could not convert image to PNG")
        return false
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        return true
    } catch {
        print("Error saving image: \(error)")
        return false
    }
}

// MARK: - Main

print("🎨 Generating Ibtida App Icon...")
print("   Background: warmCream (#FAF5EB)")
print("   Symbol: hands.sparkles.fill")
print("   Tint: mutedGold (#CCAD6B)")

let icon = generateIcon(size: 1024)

// Get the script's directory and construct output path (app icon lives in Ibtida/Ibtida/Assets.xcassets)
let scriptPath = CommandLine.arguments[0]
let scriptDir = (scriptPath as NSString).deletingLastPathComponent
let outputPath = "\(scriptDir)/Ibtida/Ibtida/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

print("📁 Output path: \(outputPath)")

if saveImage(icon, to: outputPath) {
    print("✅ Successfully created AppIcon-1024.png")
    print("")
    print("Next steps:")
    print("1. Open Xcode and verify the icon appears in Assets.xcassets")
    print("2. Clean build (Cmd+Shift+K) and rebuild")
    print("3. Run on device to see the new icon")
} else {
    print("❌ Failed to create icon")
    
    // Try alternative path (current directory)
    let altPath = "./AppIcon-1024.png"
    print("   Trying alternative path: \(altPath)")
    if saveImage(icon, to: altPath) {
        print("✅ Created AppIcon-1024.png in current directory")
        print("   Please manually move it to:")
        print("   Ibtida/Ibtida/Ibtida/Assets.xcassets/AppIcon.appiconset/")
    }
}
