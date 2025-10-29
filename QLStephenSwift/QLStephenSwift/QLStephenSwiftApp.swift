//
//  QLStephenSwiftApp.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2025/10/29.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = sender.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }
}

@main
struct QLStephenSwiftApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Settings migration moved to manual process (see README.md)
        // Automatic migration is not possible due to app sandbox restrictions
    }
    
    var body: some Scene {
        Window("QLStephenSwift", id: "main") {
            ContentView()
                .frame(width: 460, height: 420)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
