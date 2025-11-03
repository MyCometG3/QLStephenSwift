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
        
        // Load rendering settings
        let settings = TextRenderingSettings()
        
        // Determine if we need RTF rendering
        let needsRTFRendering = settings.rtfRenderingEnabled && (settings.lineNumbersEnabled || hasCustomFormatting(settings))
        
        let contentType = needsRTFRendering ? UTType.rtf : UTType.plainText
        
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
            
            // Convert data to string using detected encoding
            guard let text = String(data: data, encoding: analysisResult.encoding) else {
                reply.stringEncoding = analysisResult.encoding
                return data
            }
            
            // Apply line numbers if enabled (for plain text mode)
            var outputText = text
            if settings.lineNumbersEnabled && !needsRTFRendering {
                outputText = LineNumberFormatter.addLineNumbers(to: text, separator: settings.lineSeparator)
            }
            
            // Generate RTF if needed
            if needsRTFRendering {
                if let rtfData = RTFGenerator.generateRTF(text: text, settings: settings, encoding: analysisResult.encoding) {
                    return rtfData
                } else {
                    // Fallback to plain text if RTF generation fails
                    if settings.lineNumbersEnabled {
                        outputText = LineNumberFormatter.addLineNumbers(to: text, separator: settings.lineSeparator)
                    }
                    reply.stringEncoding = analysisResult.encoding
                    return outputText.data(using: analysisResult.encoding) ?? data
                }
            }
            
            // Return plain text
            reply.stringEncoding = analysisResult.encoding
            return outputText.data(using: analysisResult.encoding) ?? data
        }
        
        return reply
    }
    
    /// Checks if custom formatting is enabled
    private func hasCustomFormatting(_ settings: TextRenderingSettings) -> Bool {
        // Check if any non-default formatting is applied
        // For simplicity, we always consider RTF enabled as having custom formatting
        return true
    }
    
    /// Retrieves the maximum file size setting from shared storage
    /// 
    /// Priority order:
    /// 1. App Group shared UserDefaults (current method)
    /// 2. CFPreferences from legacy domain (for backward compatibility)
    /// 3. Default value if no setting found
    ///
    /// - Returns: Maximum file size in bytes
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

/// Errors that can occur during preview generation
enum PreviewError: Error {
    /// File is not supported for preview (e.g., .DS_Store)
    case unsupportedFile
    
    /// File is binary and cannot be displayed as text
    case notTextFile
    
    /// File could not be read from disk
    case cannotReadFile
}
