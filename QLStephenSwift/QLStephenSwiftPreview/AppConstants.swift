//
//  AppConstants.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2025/10/30.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation

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
}
