//
//  ContentView.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2025/10/29.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var maxFileSize: Int = AppConstants.FileSize.defaultMaxBytes
    @State private var maxFileSizeKBText: String = ""
    
    // Line number settings
    @State private var lineNumbersEnabled: Bool = AppConstants.LineNumbers.defaultEnabled
    @State private var lineSeparator: String = AppConstants.LineNumbers.defaultSeparator
    
    // RTF rendering settings
    @State private var rtfRenderingEnabled: Bool = AppConstants.RTF.defaultEnabled
    
    // Font customization settings
    @State private var contentFontName: String = AppConstants.RTF.defaultContentFontName
    @State private var contentFontSize: CGFloat = AppConstants.RTF.defaultContentFontSize
    @State private var availableFonts: [String] = []
    
    // Color customization settings
    @State private var contentForegroundColor: Color = Color.black
    @State private var contentBackgroundColor: Color = Color.white
    @State private var contentForegroundColorDark: Color = Color(white: 0.875)
    @State private var contentBackgroundColorDark: Color = Color(white: 0.118)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("QLStephenSwift")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("QuickLook Extension for Text Files")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // General Settings
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("General Settings")
                            .font(.headline)
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .help("Text files larger than this limit will be truncated in preview. (Range: \(AppConstants.FileSize.minKB) - \(AppConstants.FileSize.maxKB) KB)")
                    }
                    
                    HStack {
                        Text("Max Text File Size:")
                            .frame(width: 140, alignment: .trailing)
                        
                        TextField("100", text: $maxFileSizeKBText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                updateMaxFileSize()
                            }
                        
                        Text("KB")
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                // Line Numbers Settings
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Line Numbers")
                            .font(.headline)
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .help("Line numbers use minimum 4 digits with zero padding")
                    }
                    
                    HStack {
                        Text("Show Line Numbers:")
                            .frame(width: 140, alignment: .trailing)
                        
                        Toggle("", isOn: $lineNumbersEnabled)
                            .toggleStyle(.switch)
                            .onChange(of: lineNumbersEnabled) { _, newValue in
                                saveLineNumbersEnabled(newValue)
                            }
                        
                        Text("Separator:")
                            .frame(width: 70, alignment: .trailing)
                        
                        Picker("", selection: $lineSeparator) {
                            ForEach(AppConstants.LineNumbers.separatorOptions, id: \.0) { option in
                                Text(option.0).tag(option.1)
                            }
                        }
                        .frame(width: 100)
                        .onChange(of: lineSeparator) { _, newValue in
                            saveLineSeparator(newValue)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                // RTF Rendering Settings
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("RTF Rendering")
                            .font(.headline)
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .help("RTF mode applies font styles and colors. Requires line numbers to be enabled")
                    }
                    
                    HStack {
                        Text("Enable RTF Output:")
                            .frame(width: 140, alignment: .trailing)
                        
                        Toggle("", isOn: $rtfRenderingEnabled)
                            .toggleStyle(.switch)
                            .disabled(!lineNumbersEnabled)
                            .onChange(of: rtfRenderingEnabled) { _, newValue in
                                saveRTFEnabled(newValue)
                            }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                // Font Customization Settings
                if rtfRenderingEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Font Settings")
                                .font(.headline)
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                                .help("Monospaced fonts are listed by PostScript name (e.g., 'Osaka-Mono') to ensure fixed-pitch variants are used")
                        }
                        
                        HStack {
                            Text("Font Family:")
                                .frame(width: 140, alignment: .trailing)
                            
                            Picker("", selection: $contentFontName) {
                                ForEach(availableFonts, id: \.self) { font in
                                    Text(font).tag(font)
                                }
                            }
                            .frame(width: 140)
                            .onChange(of: contentFontName) { _, newValue in
                                saveContentFont(newValue, size: contentFontSize)
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("Font Size:")
                                .frame(width: 140, alignment: .trailing)
                            
                            Slider(value: $contentFontSize, in: AppConstants.RTF.minFontSize...AppConstants.RTF.maxFontSize, step: 1.0)
                                .frame(width: 200)
                                .onChange(of: contentFontSize) { _, newValue in
                                    saveContentFont(contentFontName, size: newValue)
                                }
                            
                            Text("\(Int(contentFontSize)) pt")
                                .frame(width: 50, alignment: .leading)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Color Customization Settings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Colors")
                                .font(.headline)
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                                .help("Colors automatically adapt based on system appearance")
                        }
                        
                        HStack {
                            Text("Light Mode:")
                                .frame(width: 140, alignment: .trailing)
                            
                            Text("Text")
                                .frame(width: 50, alignment: .trailing)
                            ColorPicker("", selection: $contentForegroundColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: contentForegroundColor) { _, newValue in
                                    saveContentColors()
                                }
                            
                            Text("Background")
                                .frame(width: 80, alignment: .trailing)
                            ColorPicker("", selection: $contentBackgroundColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: contentBackgroundColor) { _, newValue in
                                    saveContentColors()
                                }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("Dark Mode:")
                                .frame(width: 140, alignment: .trailing)
                            
                            Text("Text")
                                .frame(width: 50, alignment: .trailing)
                            ColorPicker("", selection: $contentForegroundColorDark, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: contentForegroundColorDark) { _, newValue in
                                    saveContentColors()
                                }
                            
                            Text("Background")
                                .frame(width: 80, alignment: .trailing)
                            ColorPicker("", selection: $contentBackgroundColorDark, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: contentBackgroundColorDark) { _, newValue in
                                    saveContentColors()
                                }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Links
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    
                    HStack {
                        Text("Swift Version:")
                            .frame(width: 140, alignment: .trailing)
                        Link("github.com/MyCometG3/QLStephenSwift",
                             destination: URL(string: "https://github.com/MyCometG3/QLStephenSwift")!)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Original:")
                            .frame(width: 140, alignment: .trailing)
                        Link("github.com/whomwah/qlstephen",
                             destination: URL(string: "https://github.com/whomwah/qlstephen")!)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadSettings()
        }
    }
    
    /// Loads settings from App Group shared UserDefaults
    /// Also performs one-time migration from legacy storage locations
    private func loadSettings() {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        
        // Load available monospaced fonts from system
        availableFonts = AppConstants.RTF.getAvailableMonospacedFonts()
        
        // Migrate old keys FIRST if present and not already migrated
        // This ensures correct priority: legacy settings are only used if no App Group setting exists
        migrateOldSettingsIfNeeded(to: sharedDefaults)
        
        // Load max file size
        let storedValue = sharedDefaults.integer(forKey: AppConstants.settingsKey)
        if storedValue > 0 {
            maxFileSize = storedValue
        }
        maxFileSizeKBText = String(maxFileSize / AppConstants.FileSize.bytesPerKB)
        
        // Load line numbers settings
        lineNumbersEnabled = sharedDefaults.bool(forKey: AppConstants.LineNumbers.enabledKey)
        if let separator = sharedDefaults.string(forKey: AppConstants.LineNumbers.separatorKey) {
            lineSeparator = separator
        }
        
        // Load RTF rendering settings
        rtfRenderingEnabled = sharedDefaults.bool(forKey: AppConstants.RTF.enabledKey)
        
        // Load font settings
        let storedFontName = sharedDefaults.string(forKey: AppConstants.RTF.contentFontNameKey) ?? AppConstants.RTF.defaultContentFontName
        // Validate that stored font is available, fallback to default if not
        contentFontName = availableFonts.contains(storedFontName) ? storedFontName : AppConstants.RTF.defaultContentFontName
        let fontSizeValue = sharedDefaults.double(forKey: AppConstants.RTF.contentFontSizeKey)
        contentFontSize = fontSizeValue != 0 ? CGFloat(fontSizeValue) : AppConstants.RTF.defaultContentFontSize
        
        // Load color settings
        if let fgHex = sharedDefaults.string(forKey: AppConstants.RTF.contentForegroundColorKey) {
            contentForegroundColor = colorFromHex(fgHex) ?? Color.black
        }
        if let bgHex = sharedDefaults.string(forKey: AppConstants.RTF.contentBackgroundColorKey) {
            contentBackgroundColor = colorFromHex(bgHex) ?? Color.white
        }
        if let fgDarkHex = sharedDefaults.string(forKey: AppConstants.RTF.contentForegroundColorDarkKey) {
            contentForegroundColorDark = colorFromHex(fgDarkHex) ?? Color(white: 0.875)
        }
        if let bgDarkHex = sharedDefaults.string(forKey: AppConstants.RTF.contentBackgroundColorDarkKey) {
            contentBackgroundColorDark = colorFromHex(bgDarkHex) ?? Color(white: 0.118)
        }
    }
    
    /// Migrates settings from legacy storage locations to App Group shared storage
    /// This ensures backward compatibility for users upgrading from older versions
    /// Migration only runs once - tracked by a flag in shared UserDefaults
    /// - Parameter sharedDefaults: The App Group shared UserDefaults instance
    private func migrateOldSettingsIfNeeded(to sharedDefaults: UserDefaults) {
        // Check if migration has already been completed
        let migrationKey = "settingsMigrationCompleted"
        guard !sharedDefaults.bool(forKey: migrationKey) else {
            return
        }
        
        // Only migrate if App Group storage is empty
        guard sharedDefaults.object(forKey: AppConstants.settingsKey) == nil else {
            // App Group already has a value, mark migration as complete
            sharedDefaults.set(true, forKey: migrationKey)
            return
        }
        
        let oldKeys = [
            "\(AppConstants.legacyDomain).maxFileSize",
            "maxFileSize"
        ]
        let defaults = UserDefaults.standard
        
        for oldKey in oldKeys {
            if let oldValue = defaults.object(forKey: oldKey) as? Int {
                sharedDefaults.set(oldValue, forKey: AppConstants.settingsKey)
                maxFileSize = oldValue
                defaults.removeObject(forKey: oldKey)
                break
            }
        }
        
        // Mark migration as completed
        sharedDefaults.set(true, forKey: migrationKey)
    }
    
    /// Updates the maximum file size setting when user submits the text field
    /// Validates and clamps the input to allowed range, then saves to shared storage
    private func updateMaxFileSize() {
        if let kb = Int(maxFileSizeKBText) {
            // Clip to valid range
            let clippedKB = min(max(kb, AppConstants.FileSize.minKB), AppConstants.FileSize.maxKB)
            maxFileSize = clippedKB * AppConstants.FileSize.bytesPerKB
            maxFileSizeKBText = String(clippedKB)
            
            // Save to shared settings
            guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
                return
            }
            sharedDefaults.set(maxFileSize, forKey: AppConstants.settingsKey)
        } else {
            // Restore previous value if not a number
            maxFileSizeKBText = String(maxFileSize / AppConstants.FileSize.bytesPerKB)
        }
    }
    
    /// Saves line numbers enabled setting to shared storage
    private func saveLineNumbersEnabled(_ enabled: Bool) {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        sharedDefaults.set(enabled, forKey: AppConstants.LineNumbers.enabledKey)
    }
    
    /// Saves line separator setting to shared storage
    private func saveLineSeparator(_ separator: String) {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        sharedDefaults.set(separator, forKey: AppConstants.LineNumbers.separatorKey)
    }
    
    /// Saves RTF rendering enabled setting to shared storage
    private func saveRTFEnabled(_ enabled: Bool) {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        sharedDefaults.set(enabled, forKey: AppConstants.RTF.enabledKey)
    }
    
    /// Saves content font settings to shared storage
    private func saveContentFont(_ name: String, size: CGFloat) {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        sharedDefaults.set(name, forKey: AppConstants.RTF.contentFontNameKey)
        sharedDefaults.set(Double(size), forKey: AppConstants.RTF.contentFontSizeKey)
    }
    
    /// Saves content color settings to shared storage
    private func saveContentColors() {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            return
        }
        sharedDefaults.set(colorToHex(contentForegroundColor), forKey: AppConstants.RTF.contentForegroundColorKey)
        sharedDefaults.set(colorToHex(contentBackgroundColor), forKey: AppConstants.RTF.contentBackgroundColorKey)
        sharedDefaults.set(colorToHex(contentForegroundColorDark), forKey: AppConstants.RTF.contentForegroundColorDarkKey)
        sharedDefaults.set(colorToHex(contentBackgroundColorDark), forKey: AppConstants.RTF.contentBackgroundColorDarkKey)
    }
    
    /// Convert SwiftUI Color to hex string
    private func colorToHex(_ color: Color) -> String {
        let nsColor = NSColor(color)
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
    
    /// Convert hex string to SwiftUI Color
    /// Supports #RRGGBB (6 chars) and #RRGGBBAA (8 chars) formats
    private func colorFromHex(_ hex: String) -> Color? {
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
        
        let r, g, b: Double
        
        if length == 6 {
            // Format: #RRGGBB - red at bits 16-23, green at 8-15, blue at 0-7
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        } else { // length == 8
            // Format: #RRGGBBAA - red at bits 24-31, green at 16-23, blue at 8-15, alpha at 0-7
            // Alpha is ignored in our use case (color pickers don't support opacity)
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
        }
        
        return Color(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
}
