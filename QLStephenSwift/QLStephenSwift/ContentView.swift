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
    @State private var lineNumbersEnabled: Bool = false
    @State private var lineSeparator: String = " "
    
    // RTF rendering settings
    @State private var rtfRenderingEnabled: Bool = false
    
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
                    Text("General Settings")
                        .font(.headline)
                    
                    HStack {
                        Text("Max File Size:")
                            .frame(width: 120, alignment: .trailing)
                        
                        TextField("100", text: $maxFileSizeKBText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                updateMaxFileSize()
                            }
                        
                        Text("KB")
                        
                        Spacer()
                    }
                    
                    Text("Files larger than this will be truncated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 120)
                    
                    Text("Range: \(AppConstants.FileSize.minKB) - \(AppConstants.FileSize.maxKB) KB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 120)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Line Number Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Line Number Display")
                        .font(.headline)
                    
                    HStack {
                        Toggle("Show Line Numbers", isOn: $lineNumbersEnabled)
                            .onChange(of: lineNumbersEnabled) { _, _ in
                                saveSettings()
                            }
                        Spacer()
                    }
                    .padding(.leading, 20)
                    
                    if lineNumbersEnabled {
                        HStack {
                            Text("Separator:")
                                .frame(width: 120, alignment: .trailing)
                            
                            Picker("", selection: $lineSeparator) {
                                Text("Space").tag(" ")
                                Text("Colon (:)").tag(":")
                                Text("Pipe (|)").tag("|")
                                Text("Tab").tag("\t")
                            }
                            .frame(width: 150)
                            .onChange(of: lineSeparator) { _, _ in
                                saveSettings()
                            }
                            
                            Spacer()
                        }
                        
                        Text("Separator between line number and content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 120)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // RTF Rendering Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("RTF Rendering")
                        .font(.headline)
                    
                    HStack {
                        Toggle("Enable RTF Rendering", isOn: $rtfRenderingEnabled)
                            .onChange(of: rtfRenderingEnabled) { _, _ in
                                saveSettings()
                            }
                        Spacer()
                    }
                    .padding(.leading, 20)
                    
                    if rtfRenderingEnabled {
                        Text("RTF rendering provides rich text formatting with custom fonts and colors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 120)
                        
                        Text("Note: Font customization available via defaults. See documentation.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 120)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Links
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    
                    HStack {
                        Text("Swift Version:")
                            .frame(width: 120, alignment: .trailing)
                        Link("github.com/MyCometG3/QLStephenSwift",
                             destination: URL(string: "https://github.com/MyCometG3/QLStephenSwift")!)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Original:")
                            .frame(width: 120, alignment: .trailing)
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
        .frame(minWidth: 500, minHeight: 600)
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
        
        // Migrate old keys FIRST if present and not already migrated
        // This ensures correct priority: legacy settings are only used if no App Group setting exists
        migrateOldSettingsIfNeeded(to: sharedDefaults)
        
        // Load from shared settings (after migration)
        let storedValue = sharedDefaults.integer(forKey: AppConstants.settingsKey)
        if storedValue > 0 {
            maxFileSize = storedValue
        }
        
        maxFileSizeKBText = String(maxFileSize / AppConstants.FileSize.bytesPerKB)
        
        // Load formatting settings
        let formattingSettings = TextFormattingSettings.load()
        lineNumbersEnabled = formattingSettings.lineNumbersEnabled
        lineSeparator = formattingSettings.lineSeparator
        rtfRenderingEnabled = formattingSettings.rtfRenderingEnabled
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
    
    /// Saves formatting settings to shared UserDefaults
    private func saveSettings() {
        var settings = TextFormattingSettings.load()
        settings.lineNumbersEnabled = lineNumbersEnabled
        settings.lineSeparator = lineSeparator
        settings.rtfRenderingEnabled = rtfRenderingEnabled
        settings.save()
    }
}

// MARK: - Preview for TextFormattingSettings
extension TextFormattingSettings {
    // This extension is needed to make TextFormattingSettings available in the main app module
}

#Preview {
    ContentView()
}
