//
//  PreviewProvider.swift
//  QLStephenSwiftPreview
//
//  Created by Takashi Mochizuki on 2025/10/29.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Cocoa
import Quartz
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let fileURL = request.fileURL
        
        // Ignore .DS_Store files
        if fileURL.lastPathComponent == ".DS_Store" {
            throw PreviewError.unsupportedFile
        }
        
        // Analyze file to determine if it's text and detect encoding
        let analysisResult = try FileAnalyzer.analyze(fileURL: fileURL)
        
        guard analysisResult.isTextFile else {
            throw PreviewError.notTextFile
        }
        
        // Get max file size from user defaults
        let maxFileSize = getMaxFileSize()
        
        // Get file size
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int else {
            throw PreviewError.cannotReadFile
        }
        
        let contentType = UTType.plainText
        
        let reply = QLPreviewReply(dataOfContentType: contentType, contentSize: .zero) { reply in
            var data: Data
            
            if fileSize > maxFileSize {
                // Read only up to maxFileSize
                guard let fileHandle = try? FileHandle(forReadingFrom: fileURL),
                      let limitedData = try? fileHandle.read(upToCount: maxFileSize) else {
                    return Data()
                }
                try? fileHandle.close()
                data = limitedData
            } else {
                // Read entire file
                guard let fileData = try? Data(contentsOf: fileURL) else {
                    return Data()
                }
                data = fileData
            }
            
            reply.stringEncoding = analysisResult.encoding
            return data
        }
        
        return reply
    }
    
    private func getMaxFileSize() -> Int {
        // Use App Group shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            let intValue = sharedDefaults.integer(forKey: AppConstants.settingsKey)
            if intValue > 0 {
                return intValue
            }
        }
        
        // Legacy fallback: Try CFPreferences (for migration)
        let maxFileSizeRef = CFPreferencesCopyAppValue(
            AppConstants.settingsKey as CFString,
            AppConstants.legacyDomain as CFString
        )
        
        if let maxFileSize = maxFileSizeRef as? Int, maxFileSize > 0 {
            return maxFileSize
        } else if let maxFileSize = maxFileSizeRef as? NSNumber, maxFileSize.intValue > 0 {
            return maxFileSize.intValue
        }
        
        return AppConstants.FileSize.defaultMaxBytes
    }
}

enum PreviewError: Error {
    case unsupportedFile
    case notTextFile
    case cannotReadFile
}
