//
//  AppConstants.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2025/10/30.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation

enum AppConstants {
    static let appGroupID = "group.com.mycometg3.qlstephenswift"
    static let settingsKey = "maxFileSize"
    static let legacyDomain = "com.mycometg3.qlstephenswift"
    
    enum FileSize {
        static let bytesPerKB = 1024
        static let defaultMaxBytes = 100 * bytesPerKB  // 100KB
        static let minKB = 100
        static let maxKB = 10240  // 10MB
    }
}
