//
//  TextFormattingSettings.swift
//  QLStephenSwiftPreview
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import AppKit

/// Settings for text formatting and rendering options
struct TextFormattingSettings {
    // MARK: - Line Number Settings
    
    /// Whether to display line numbers
    var lineNumbersEnabled: Bool
    
    /// Separator between line number and content
    var lineSeparator: String
    
    // MARK: - RTF Rendering Settings
    
    /// Whether to render as RTF with attributed strings
    var rtfRenderingEnabled: Bool
    
    /// Font settings for line numbers
    var lineNumberFont: FontAttributes
    
    /// Font settings for content text
    var contentFont: FontAttributes
    
    /// Tab width configuration
    var tabWidth: TabWidthSettings
    
    // MARK: - Font Attributes
    
    struct FontAttributes {
        var fontName: String
        var fontSize: CGFloat
        var textColor: NSColor
        var backgroundColor: NSColor?
        
        static var `default`: FontAttributes {
            FontAttributes(
                fontName: "Menlo",
                fontSize: 11.0,
                textColor: .textColor,
                backgroundColor: nil
            )
        }
        
        static var defaultLineNumber: FontAttributes {
            FontAttributes(
                fontName: "Menlo",
                fontSize: 11.0,
                textColor: .secondaryLabelColor,
                backgroundColor: NSColor(white: 0.95, alpha: 1.0)
            )
        }
    }
    
    // MARK: - Tab Width Settings
    
    struct TabWidthSettings {
        enum Mode: String, Codable {
            case characters
            case points
        }
        
        var mode: Mode
        var value: CGFloat
        
        static var `default`: TabWidthSettings {
            TabWidthSettings(mode: .characters, value: 4.0)
        }
    }
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let lineNumbersEnabled = "lineNumbersEnabled"
        static let lineSeparator = "lineSeparator"
        static let rtfRenderingEnabled = "rtfRenderingEnabled"
        
        // Line number font
        static let lineNumberFontName = "lineNumberFontName"
        static let lineNumberFontSize = "lineNumberFontSize"
        static let lineNumberTextColor = "lineNumberTextColor"
        static let lineNumberBackgroundColor = "lineNumberBackgroundColor"
        
        // Content font
        static let contentFontName = "contentFontName"
        static let contentFontSize = "contentFontSize"
        static let contentTextColor = "contentTextColor"
        static let contentBackgroundColor = "contentBackgroundColor"
        
        // Tab width
        static let tabWidthMode = "tabWidthMode"
        static let tabWidthValue = "tabWidthValue"
    }
    
    // MARK: - Default Values
    
    static var `default`: TextFormattingSettings {
        TextFormattingSettings(
            lineNumbersEnabled: false,
            lineSeparator: " ",
            rtfRenderingEnabled: false,
            lineNumberFont: .defaultLineNumber,
            contentFont: .default,
            tabWidth: .default
        )
    }
    
    // MARK: - Load/Save
    
    /// Loads settings from shared UserDefaults
    static func load() -> TextFormattingSettings {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return .default
        }
        
        return TextFormattingSettings(
            lineNumbersEnabled: sharedDefaults.bool(forKey: Keys.lineNumbersEnabled),
            lineSeparator: sharedDefaults.string(forKey: Keys.lineSeparator) ?? " ",
            rtfRenderingEnabled: sharedDefaults.bool(forKey: Keys.rtfRenderingEnabled),
            lineNumberFont: FontAttributes(
                fontName: sharedDefaults.string(forKey: Keys.lineNumberFontName) ?? "Menlo",
                fontSize: CGFloat(sharedDefaults.double(forKey: Keys.lineNumberFontSize) != 0 ? 
                                sharedDefaults.double(forKey: Keys.lineNumberFontSize) : 11.0),
                textColor: loadColor(from: sharedDefaults, key: Keys.lineNumberTextColor) ?? .secondaryLabelColor,
                backgroundColor: loadColor(from: sharedDefaults, key: Keys.lineNumberBackgroundColor) ?? 
                               NSColor(white: 0.95, alpha: 1.0)
            ),
            contentFont: FontAttributes(
                fontName: sharedDefaults.string(forKey: Keys.contentFontName) ?? "Menlo",
                fontSize: CGFloat(sharedDefaults.double(forKey: Keys.contentFontSize) != 0 ?
                                sharedDefaults.double(forKey: Keys.contentFontSize) : 11.0),
                textColor: loadColor(from: sharedDefaults, key: Keys.contentTextColor) ?? .textColor,
                backgroundColor: loadColor(from: sharedDefaults, key: Keys.contentBackgroundColor)
            ),
            tabWidth: TabWidthSettings(
                mode: TabWidthSettings.Mode(rawValue: sharedDefaults.string(forKey: Keys.tabWidthMode) ?? "characters") ?? .characters,
                value: CGFloat(sharedDefaults.double(forKey: Keys.tabWidthValue) != 0 ?
                             sharedDefaults.double(forKey: Keys.tabWidthValue) : 4.0)
            )
        )
    }
    
    /// Saves settings to shared UserDefaults
    func save() {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        
        sharedDefaults.set(lineNumbersEnabled, forKey: Keys.lineNumbersEnabled)
        sharedDefaults.set(lineSeparator, forKey: Keys.lineSeparator)
        sharedDefaults.set(rtfRenderingEnabled, forKey: Keys.rtfRenderingEnabled)
        
        // Line number font
        sharedDefaults.set(lineNumberFont.fontName, forKey: Keys.lineNumberFontName)
        sharedDefaults.set(Double(lineNumberFont.fontSize), forKey: Keys.lineNumberFontSize)
        saveColor(lineNumberFont.textColor, to: sharedDefaults, key: Keys.lineNumberTextColor)
        if let bgColor = lineNumberFont.backgroundColor {
            saveColor(bgColor, to: sharedDefaults, key: Keys.lineNumberBackgroundColor)
        }
        
        // Content font
        sharedDefaults.set(contentFont.fontName, forKey: Keys.contentFontName)
        sharedDefaults.set(Double(contentFont.fontSize), forKey: Keys.contentFontSize)
        saveColor(contentFont.textColor, to: sharedDefaults, key: Keys.contentTextColor)
        if let bgColor = contentFont.backgroundColor {
            saveColor(bgColor, to: sharedDefaults, key: Keys.contentBackgroundColor)
        }
        
        // Tab width
        sharedDefaults.set(tabWidth.mode.rawValue, forKey: Keys.tabWidthMode)
        sharedDefaults.set(Double(tabWidth.value), forKey: Keys.tabWidthValue)
    }
    
    // MARK: - Color Helpers
    
    private static func loadColor(from defaults: UserDefaults, key: String) -> NSColor? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    }
    
    private func saveColor(_ color: NSColor, to defaults: UserDefaults, key: String) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            defaults.set(data, forKey: key)
        }
    }
}
