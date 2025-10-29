//
//  QLStephenSwiftApp.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2025/10/29.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import SwiftUI

@main
struct QLStephenSwiftApp: App {
    
    init() {
        // Settings migration moved to manual process (see README.md)
        // Automatic migration is not possible due to app sandbox restrictions
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
