//
//  ContentView.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2025/10/29.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("com.mycometg3.qlstephenswift.maxFileSize") private var maxFileSize: Int = 102400
    @State private var maxFileSizeKBText: String = ""
    
    private let minFileSizeKB = 100
    private let maxFileSizeKBLimit = 10240  // 10MB
    
    var body: some View {
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
            
            // Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings")
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
                
                Text("Range: \(minFileSizeKB) - \(maxFileSizeKBLimit) KB")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 120)
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
        .onAppear {
            maxFileSizeKBText = String(maxFileSize / 1024)
        }
    }
    
    private func updateMaxFileSize() {
        if let kb = Int(maxFileSizeKBText) {
            // Clip to valid range
            let clippedKB = min(max(kb, minFileSizeKB), maxFileSizeKBLimit)
            maxFileSize = clippedKB * 1024
            maxFileSizeKBText = String(clippedKB)
        } else {
            // Restore previous value if not a number
            maxFileSizeKBText = String(maxFileSize / 1024)
        }
    }
}

#Preview {
    ContentView()
}
