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
                    
                    Text("Files larger than this will be truncated. (Range: \(AppConstants.FileSize.minKB) - \(AppConstants.FileSize.maxKB) KB)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 120)
                }
                .padding(.horizontal)
                
                // Line Numbers Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Line Numbers")
                        .font(.headline)
                    
                    HStack {
                        Text("Show Line Numbers:")
                            .frame(width: 140, alignment: .trailing)
                        
                        Toggle("", isOn: $lineNumbersEnabled)
                            .toggleStyle(.switch)
                            .onChange(of: lineNumbersEnabled) { _, newValue in
                                saveLineNumbersEnabled(newValue)
                            }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Separator:")
                            .frame(width: 140, alignment: .trailing)
                        
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
                    
                    Text("Line numbers use minimum 4 digits with zero padding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 140)
                }
                .padding(.horizontal)
                
                // RTF Rendering Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("RTF Rendering")
                        .font(.headline)
                    
                    HStack {
                        Text("Enable RTF Output:")
                            .frame(width: 140, alignment: .trailing)
                        
                        Toggle("", isOn: $rtfRenderingEnabled)
                            .toggleStyle(.switch)
                            .onChange(of: rtfRenderingEnabled) { _, newValue in
                                saveRTFEnabled(newValue)
                            }
                        
                        Spacer()
                    }
                    
                    Text("RTF mode applies font styles and colors. Advanced font settings can be configured via defaults")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 140)
                }
                .padding(.horizontal)
                
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
}

#Preview {
    ContentView()
}
