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
        
        // Load formatting settings
        let settings = TextFormattingSettings.load()
        
        // Check if we should use RTF rendering
        if settings.rtfRenderingEnabled {
            return try provideRTFPreview(fileURL: fileURL, 
                                        encoding: analysisResult.encoding,
                                        fileSize: fileSize,
                                        maxFileSize: maxFileSize,
                                        settings: settings)
        } else {
            // Use original plain text rendering
            return try providePlainTextPreview(fileURL: fileURL,
                                              encoding: analysisResult.encoding,
                                              fileSize: fileSize,
                                              maxFileSize: maxFileSize,
                                              settings: settings)
        }
    }
    
    /// Provides plain text preview (original behavior, optionally with line numbers)
    private func providePlainTextPreview(fileURL: URL,
                                        encoding: String.Encoding,
                                        fileSize: Int,
                                        maxFileSize: Int,
                                        settings: TextFormattingSettings) throws -> QLPreviewReply {
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
            
            // If line numbers are enabled but RTF is not, add line numbers to plain text
            if settings.lineNumbersEnabled {
                if let text = String(data: data, encoding: encoding) {
                    let numberedText = self.addLineNumbersToPlainText(text: text, 
                                                                      separator: settings.lineSeparator)
                    if let numberedData = numberedText.data(using: encoding) {
                        data = numberedData
                    }
                }
            }
            
            reply.stringEncoding = encoding
            return data
        }
        
        return reply
    }
    
    /// Provides RTF preview with attributed strings
    private func provideRTFPreview(fileURL: URL,
                                   encoding: String.Encoding,
                                   fileSize: Int,
                                   maxFileSize: Int,
                                   settings: TextFormattingSettings) throws -> QLPreviewReply {
        let contentType = UTType.rtf
        
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
            guard let text = String(data: data, encoding: encoding) else {
                return Data()
            }
            
            // Render as attributed string
            let attributedString = AttributedTextRenderer.render(text: text, settings: settings)
            
            // Convert to RTF data
            let range = NSRange(location: 0, length: attributedString.length)
            guard let rtfData = try? attributedString.data(from: range,
                                                          documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) else {
                return Data()
            }
            
            return rtfData
        }
        
        return reply
    }
    
    /// Adds line numbers to plain text (when RTF is disabled)
    private func addLineNumbersToPlainText(text: String, separator: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let lineCount = lines.count
        let digitCount = max(4, String(lineCount).count)
        
        let resolvedSeparator = resolveSeparator(separator)
        
        var result = ""
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let lineNumberString = String(format: "%0*d", digitCount, lineNumber)
            result += lineNumberString + resolvedSeparator + line
            
            // Add newline if not the last line, or if original text ended with newline
            if index < lines.count - 1 || text.hasSuffix("\n") {
                result += "\n"
            }
        }
        
        return result
    }
    
    /// Resolves separator string from setting
    private func resolveSeparator(_ separator: String) -> String {
        switch separator.lowercased() {
        case "space", " ":
            return " "
        case "tab", "\\t", "\t":
            return "\t"
        case ":", "colon":
            return ":"
        case "|", "pipe":
            return "|"
        default:
            return separator
        }
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
