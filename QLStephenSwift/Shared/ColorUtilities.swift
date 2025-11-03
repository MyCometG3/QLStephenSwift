//
//  ColorUtilities.swift
//  QLStephenSwift
//
//  Shared utility for color conversion across main app and extension.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import SwiftUI
import AppKit

/// Shared utilities for color conversion between hex strings and Color/NSColor
enum ColorUtilities {
    /// Convert hex string to NSColor
    /// Supports #RRGGBB (6 chars) and #RRGGBBAA (8 chars) formats
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "#FF0000FF")
    /// - Returns: NSColor if parsing succeeds, nil otherwise
    static func nsColorFromHex(_ hex: String) -> NSColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        // Validate length before parsing
        let length = hexSanitized.count
        guard length == 6 || length == 8 else {
            return nil
        }
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r, g, b: CGFloat
        
        if length == 6 {
            // Format: #RRGGBB - red at bits 16-23, green at 8-15, blue at 0-7
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else { // length == 8
            // Format: #RRGGBBAA - red at bits 24-31, green at 16-23, blue at 8-15, alpha at 0-7
            // Alpha channel is not extracted as we always use full opacity (alpha = 1.0) for RTF rendering
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
        }
        
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)
    }
    
    /// Convert hex string to SwiftUI Color
    /// Supports #RRGGBB (6 chars) and #RRGGBBAA (8 chars) formats
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "#FF0000FF")
    /// - Returns: Color if parsing succeeds, nil otherwise
    static func colorFromHex(_ hex: String) -> Color? {
        guard let nsColor = nsColorFromHex(hex) else {
            return nil
        }
        return Color(nsColor)
    }
    
    /// Convert SwiftUI Color to hex string
    /// - Parameter color: SwiftUI Color to convert
    /// - Returns: Hex string in #RRGGBB format
    static func colorToHex(_ color: Color) -> String {
        let nsColor = NSColor(color)
        return nsColorToHex(nsColor)
    }
    
    /// Convert NSColor to hex string
    /// - Parameter nsColor: NSColor to convert
    /// - Returns: Hex string in #RRGGBB format
    static func nsColorToHex(_ nsColor: NSColor) -> String {
        // Try sRGB first, then deviceRGB as fallback
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor.usingColorSpace(.deviceRGB)
        guard let finalColor = rgbColor else {
            return "#000000"
        }
        let r = Int(finalColor.redComponent * 255)
        let g = Int(finalColor.greenComponent * 255)
        let b = Int(finalColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
