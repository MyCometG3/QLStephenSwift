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
        
        // Get formatting settings
        let settings = getFormattingSettings()
        
        // Get file size
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int else {
            throw PreviewError.cannotReadFile
        }
        
        // Determine content type based on formatting settings
        let contentType: UTType
        if settings.rtfRenderingEnabled {
            contentType = UTType.rtf
        } else {
            contentType = UTType.plainText
        }
        
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
            
            // If line numbers or RTF rendering are enabled, format the text
            if settings.lineNumbersEnabled || settings.rtfRenderingEnabled {
                // Decode the text using detected encoding
                guard let text = String(data: data, encoding: analysisResult.encoding) else {
                    // Fallback: return original data if decoding fails
                    reply.stringEncoding = analysisResult.encoding
                    return data
                }
                
                // Format the text with line numbers and/or RTF
                if let formattedData = TextFormatter.format(text: text, with: settings) {
                    // For RTF, don't set stringEncoding
                    if !settings.rtfRenderingEnabled {
                        reply.stringEncoding = .utf8
                    }
                    return formattedData
                } else {
                    // Fallback: return original data if formatting fails
                    reply.stringEncoding = analysisResult.encoding
                    return data
                }
            } else {
                // Original behavior: return raw data with encoding
                reply.stringEncoding = analysisResult.encoding
                return data
            }
        }
        
        return reply
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
    
    /// Retrieves formatting settings from shared storage
    /// - Returns: TextFormatter settings
    private func getFormattingSettings() -> TextFormatter.Settings {
        if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            return TextFormatter.Settings.load(from: sharedDefaults)
        }
        
        // Fallback to default settings if shared defaults unavailable
        return TextFormatter.Settings(
            lineNumbersEnabled: AppConstants.LineNumbers.defaultEnabled,
            lineSeparator: AppConstants.LineNumbers.defaultSeparator,
            rtfRenderingEnabled: AppConstants.RTF.defaultEnabled,
            lineNumberFontName: AppConstants.RTF.defaultLineNumberFontName,
            lineNumberFontSize: AppConstants.RTF.defaultLineNumberFontSize,
            lineNumberForegroundColor: AppConstants.RTF.defaultLineNumberForegroundColor,
            lineNumberBackgroundColor: AppConstants.RTF.defaultLineNumberBackgroundColor,
            contentFontName: AppConstants.RTF.defaultContentFontName,
            contentFontSize: AppConstants.RTF.defaultContentFontSize,
            contentForegroundColor: AppConstants.RTF.defaultContentForegroundColor,
            contentBackgroundColor: AppConstants.RTF.defaultContentBackgroundColor,
            tabWidthMode: AppConstants.RTF.defaultTabWidthMode,
            tabWidthValue: AppConstants.RTF.defaultTabWidthValue
        )
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
