//
//  TextRenderingSettings.swift
//  QLStephenSwiftPreview
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import AppKit

/// Manages text rendering settings for the QuickLook preview extension
/// All settings are persisted in App Group shared UserDefaults
struct TextRenderingSettings {
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let lineNumbersEnabled = "lineNumbersEnabled"
        static let lineSeparator = "lineSeparator"
        static let rtfRenderingEnabled = "rtfRenderingEnabled"
        
        // Line number font settings
        static let lineNumberFontName = "lineNumberFontName"
        static let lineNumberFontSize = "lineNumberFontSize"
        static let lineNumberTextColor = "lineNumberTextColor"
        static let lineNumberBackgroundColor = "lineNumberBackgroundColor"
        
        // Content font settings
        static let contentFontName = "contentFontName"
        static let contentFontSize = "contentFontSize"
        static let contentTextColor = "contentTextColor"
        static let contentBackgroundColor = "contentBackgroundColor"
        
        // Tab width settings
        static let tabWidthMode = "tabWidthMode"
        static let tabWidthValue = "tabWidthValue"
    }
    
    // MARK: - Default Values
    private enum Defaults {
        static let lineNumbersEnabled = false
        static let lineSeparator = " | "
        static let rtfRenderingEnabled = false
        
        static let lineNumberFontName = "Menlo"
        static let lineNumberFontSize: CGFloat = 11.0
        static let lineNumberTextColor = "#888888"
        static let lineNumberBackgroundColor = "#F0F0F0"
        
        static let contentFontName = "Menlo"
        static let contentFontSize: CGFloat = 11.0
        static let contentTextColor = "#000000"
        static let contentBackgroundColor = "#FFFFFF"
        
        static let tabWidthMode = TabWidthMode.characters
        static let tabWidthValue: CGFloat = 4.0
    }
    
    // MARK: - Tab Width Mode
    enum TabWidthMode: String, Codable {
        case characters
        case points
    }
    
    // MARK: - Properties
    let lineNumbersEnabled: Bool
    let lineSeparator: String
    let rtfRenderingEnabled: Bool
    
    let lineNumberFontName: String
    let lineNumberFontSize: CGFloat
    let lineNumberTextColor: String
    let lineNumberBackgroundColor: String
    
    let contentFontName: String
    let contentFontSize: CGFloat
    let contentTextColor: String
    let contentBackgroundColor: String
    
    let tabWidthMode: TabWidthMode
    let tabWidthValue: CGFloat
    
    // MARK: - Initialization
    
    /// Loads settings from App Group shared UserDefaults
    init() {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            // Fallback to default values if shared defaults unavailable
            self.lineNumbersEnabled = Defaults.lineNumbersEnabled
            self.lineSeparator = Defaults.lineSeparator
            self.rtfRenderingEnabled = Defaults.rtfRenderingEnabled
            
            self.lineNumberFontName = Defaults.lineNumberFontName
            self.lineNumberFontSize = Defaults.lineNumberFontSize
            self.lineNumberTextColor = Defaults.lineNumberTextColor
            self.lineNumberBackgroundColor = Defaults.lineNumberBackgroundColor
            
            self.contentFontName = Defaults.contentFontName
            self.contentFontSize = Defaults.contentFontSize
            self.contentTextColor = Defaults.contentTextColor
            self.contentBackgroundColor = Defaults.contentBackgroundColor
            
            self.tabWidthMode = Defaults.tabWidthMode
            self.tabWidthValue = Defaults.tabWidthValue
            return
        }
        
        // Load line number settings
        self.lineNumbersEnabled = sharedDefaults.bool(forKey: Keys.lineNumbersEnabled)
        self.lineSeparator = sharedDefaults.string(forKey: Keys.lineSeparator) ?? Defaults.lineSeparator
        self.rtfRenderingEnabled = sharedDefaults.bool(forKey: Keys.rtfRenderingEnabled)
        
        // Load line number font settings
        self.lineNumberFontName = sharedDefaults.string(forKey: Keys.lineNumberFontName) ?? Defaults.lineNumberFontName
        let loadedLineNumberFontSize = CGFloat(sharedDefaults.double(forKey: Keys.lineNumberFontSize))
        self.lineNumberFontSize = loadedLineNumberFontSize > 0 ? loadedLineNumberFontSize : Defaults.lineNumberFontSize
        self.lineNumberTextColor = sharedDefaults.string(forKey: Keys.lineNumberTextColor) ?? Defaults.lineNumberTextColor
        self.lineNumberBackgroundColor = sharedDefaults.string(forKey: Keys.lineNumberBackgroundColor) ?? Defaults.lineNumberBackgroundColor
        
        // Load content font settings
        self.contentFontName = sharedDefaults.string(forKey: Keys.contentFontName) ?? Defaults.contentFontName
        let loadedContentFontSize = CGFloat(sharedDefaults.double(forKey: Keys.contentFontSize))
        self.contentFontSize = loadedContentFontSize > 0 ? loadedContentFontSize : Defaults.contentFontSize
        self.contentTextColor = sharedDefaults.string(forKey: Keys.contentTextColor) ?? Defaults.contentTextColor
        self.contentBackgroundColor = sharedDefaults.string(forKey: Keys.contentBackgroundColor) ?? Defaults.contentBackgroundColor
        
        // Load tab width settings
        if let modeString = sharedDefaults.string(forKey: Keys.tabWidthMode),
           let mode = TabWidthMode(rawValue: modeString) {
            self.tabWidthMode = mode
        } else {
            self.tabWidthMode = Defaults.tabWidthMode
        }
        
        let loadedTabWidth = CGFloat(sharedDefaults.double(forKey: Keys.tabWidthValue))
        self.tabWidthValue = loadedTabWidth > 0 ? loadedTabWidth : Defaults.tabWidthValue
    }
    
    // MARK: - Save Methods
    
    /// Saves settings to App Group shared UserDefaults
    func save() {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        
        sharedDefaults.set(lineNumbersEnabled, forKey: Keys.lineNumbersEnabled)
        sharedDefaults.set(lineSeparator, forKey: Keys.lineSeparator)
        sharedDefaults.set(rtfRenderingEnabled, forKey: Keys.rtfRenderingEnabled)
        
        sharedDefaults.set(lineNumberFontName, forKey: Keys.lineNumberFontName)
        sharedDefaults.set(Double(lineNumberFontSize), forKey: Keys.lineNumberFontSize)
        sharedDefaults.set(lineNumberTextColor, forKey: Keys.lineNumberTextColor)
        sharedDefaults.set(lineNumberBackgroundColor, forKey: Keys.lineNumberBackgroundColor)
        
        sharedDefaults.set(contentFontName, forKey: Keys.contentFontName)
        sharedDefaults.set(Double(contentFontSize), forKey: Keys.contentFontSize)
        sharedDefaults.set(contentTextColor, forKey: Keys.contentTextColor)
        sharedDefaults.set(contentBackgroundColor, forKey: Keys.contentBackgroundColor)
        
        sharedDefaults.set(tabWidthMode.rawValue, forKey: Keys.tabWidthMode)
        sharedDefaults.set(Double(tabWidthValue), forKey: Keys.tabWidthValue)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a mutable copy of the settings
    func toMutable() -> MutableTextRenderingSettings {
        return MutableTextRenderingSettings(
            lineNumbersEnabled: lineNumbersEnabled,
            lineSeparator: lineSeparator,
            rtfRenderingEnabled: rtfRenderingEnabled,
            lineNumberFontName: lineNumberFontName,
            lineNumberFontSize: lineNumberFontSize,
            lineNumberTextColor: lineNumberTextColor,
            lineNumberBackgroundColor: lineNumberBackgroundColor,
            contentFontName: contentFontName,
            contentFontSize: contentFontSize,
            contentTextColor: contentTextColor,
            contentBackgroundColor: contentBackgroundColor,
            tabWidthMode: tabWidthMode,
            tabWidthValue: tabWidthValue
        )
    }
}

/// Mutable version of TextRenderingSettings for UI binding
struct MutableTextRenderingSettings {
    var lineNumbersEnabled: Bool
    var lineSeparator: String
    var rtfRenderingEnabled: Bool
    
    var lineNumberFontName: String
    var lineNumberFontSize: CGFloat
    var lineNumberTextColor: String
    var lineNumberBackgroundColor: String
    
    var contentFontName: String
    var contentFontSize: CGFloat
    var contentTextColor: String
    var contentBackgroundColor: String
    
    var tabWidthMode: TextRenderingSettings.TabWidthMode
    var tabWidthValue: CGFloat
    
    /// Converts to immutable settings
    func toImmutable() -> TextRenderingSettings {
        // Note: This creates a settings instance but doesn't load from UserDefaults
        // We need to save first, then reload
        let settings = TextRenderingSettings()
        // Create a temporary instance with our values
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return settings
        }
        
        // Save all values
        sharedDefaults.set(lineNumbersEnabled, forKey: "lineNumbersEnabled")
        sharedDefaults.set(lineSeparator, forKey: "lineSeparator")
        sharedDefaults.set(rtfRenderingEnabled, forKey: "rtfRenderingEnabled")
        
        sharedDefaults.set(lineNumberFontName, forKey: "lineNumberFontName")
        sharedDefaults.set(Double(lineNumberFontSize), forKey: "lineNumberFontSize")
        sharedDefaults.set(lineNumberTextColor, forKey: "lineNumberTextColor")
        sharedDefaults.set(lineNumberBackgroundColor, forKey: "lineNumberBackgroundColor")
        
        sharedDefaults.set(contentFontName, forKey: "contentFontName")
        sharedDefaults.set(Double(contentFontSize), forKey: "contentFontSize")
        sharedDefaults.set(contentTextColor, forKey: "contentTextColor")
        sharedDefaults.set(contentBackgroundColor, forKey: "contentBackgroundColor")
        
        sharedDefaults.set(tabWidthMode.rawValue, forKey: "tabWidthMode")
        sharedDefaults.set(Double(tabWidthValue), forKey: "tabWidthValue")
        
        // Reload and return
        return TextRenderingSettings()
    }
}
