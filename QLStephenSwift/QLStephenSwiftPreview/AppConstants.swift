//
//  AppConstants.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2025/10/30.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import AppKit

/// Shared constants used across the main app and Quick Look extension.
/// Using App Groups to share settings between sandboxed processes.
enum AppConstants {
    /// App Group identifier for sharing UserDefaults between main app and extension
    static let appGroupID = "group.com.mycometg3.qlstephenswift"
    
    /// UserDefaults key for storing maximum file size setting
    static let settingsKey = "maxFileSize"
    
    /// Legacy domain identifier for backward compatibility with older versions
    static let legacyDomain = "com.mycometg3.qlstephenswift"
    
    /// File size related constants
    enum FileSize {
        /// Bytes per kilobyte conversion factor
        static let bytesPerKB = 1024
        
        /// Default maximum file size for preview (100KB)
        static let defaultMaxBytes = 100 * bytesPerKB
        
        /// Minimum allowed file size in KB for user configuration
        static let minKB = 100
        
        /// Maximum allowed file size in KB for user configuration (10MB)
        static let maxKB = 10240
    }
    
    /// Line number display settings
    enum LineNumbers {
        /// UserDefaults key for line numbers enabled setting
        static let enabledKey = "lineNumbersEnabled"
        
        /// UserDefaults key for line separator setting
        static let separatorKey = "lineSeparator"
        
        /// Default value for line numbers enabled
        static let defaultEnabled = false
        
        /// Default line separator
        static let defaultSeparator = " "
        
        /// Minimum digit width for line numbers
        static let minDigits = 4
        
        /// Available separator options
        static let separatorOptions = [
            ("space", " "),
            ("colon", ":"),
            ("pipe", "|"),
            ("tab", "\t")
        ]
    }
    
    /// RTF rendering settings
    enum RTF {
        /// UserDefaults key for RTF rendering enabled setting
        static let enabledKey = "rtfRenderingEnabled"
        
        /// Default value for RTF rendering enabled
        static let defaultEnabled = false
        
        /// Line number font settings keys
        static let lineNumberFontNameKey = "lineNumberFontName"
        static let lineNumberFontSizeKey = "lineNumberFontSize"
        static let lineNumberForegroundColorKey = "lineNumberForegroundColor"
        static let lineNumberBackgroundColorKey = "lineNumberBackgroundColor"
        
        /// Content font settings keys
        static let contentFontNameKey = "contentFontName"
        static let contentFontSizeKey = "contentFontSize"
        static let contentForegroundColorKey = "contentForegroundColor"
        static let contentBackgroundColorKey = "contentBackgroundColor"
        
        /// Dark mode specific color keys
        static let contentForegroundColorDarkKey = "contentForegroundColorDark"
        static let contentBackgroundColorDarkKey = "contentBackgroundColorDark"
        
        /// Tab width settings keys
        static let tabWidthModeKey = "tabWidthMode"
        static let tabWidthValueKey = "tabWidthValue"
        
        /// Default font settings
        static let defaultLineNumberFontName = "Menlo"
        static let defaultLineNumberFontSize: CGFloat = 11.0
        static let defaultLineNumberForegroundColor = "#808080" // Gray
        static let defaultLineNumberBackgroundColor = "#F5F5F5" // Light gray
        
        static let defaultContentFontName = "Menlo"
        static let defaultContentFontSize: CGFloat = 11.0
        static let defaultContentForegroundColor = "#000000" // Black
        static let defaultContentBackgroundColor = "#FFFFFF" // White
        
        /// Default dark mode colors
        static let defaultContentForegroundColorDark = "#E0E0E0" // Light gray text
        static let defaultContentBackgroundColorDark = "#1E1E1E" // Dark background
        
        /// Get list of available monospaced fonts installed on the system
        /// Returns PostScript names of monospaced font variants to ensure proper font selection
        /// Delegates to shared FontUtilities to avoid code duplication
        static func getAvailableMonospacedFonts() -> [String] {
            return FontUtilities.getAvailableMonospacedFonts()
        }
        
        /// Font size range
        static let minFontSize: CGFloat = 8.0
        static let maxFontSize: CGFloat = 24.0
        
        /// Tab width mode options
        enum TabWidthMode: String {
            case characters = "characters"
            case points = "points"
        }
        
        static let defaultTabWidthMode = TabWidthMode.characters.rawValue
        static let defaultTabWidthValue: Double = 4.0
    }
}
