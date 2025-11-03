//
//  FontUtilities.swift
//  QLStephenSwift
//
//  Shared utility for font management across main app and extension.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import AppKit

/// Shared utilities for font detection and management
enum FontUtilities {
    /// Get list of available monospaced fonts installed on the system
    /// Returns PostScript names of monospaced font variants to ensure proper font selection
    static func getAvailableMonospacedFonts() -> [String] {
        let fontManager = NSFontManager.shared
        var monospacedFonts = Set<String>()
        
        // Get all available font families
        let allFontFamilies = fontManager.availableFontFamilies
        
        for familyName in allFontFamilies {
            // Get font members for this family
            if let fontMembers = fontManager.availableMembers(ofFontFamily: familyName) {
                for member in fontMembers {
                    // member is an array: [PostScript name, display name, weight, traits]
                    if let psName = member[0] as? String,
                       let traits = member[3] as? UInt,
                       (traits & NSFontTraitMask.fixedPitchFontMask.rawValue) != 0 {
                        // Use PostScript name to ensure we get the monospaced variant
                        // e.g., "Osaka-Mono" instead of "Osaka"
                        monospacedFonts.insert(psName)
                    }
                }
            }
        }
        
        // Sort alphabetically and return
        return monospacedFonts.sorted()
    }
}
