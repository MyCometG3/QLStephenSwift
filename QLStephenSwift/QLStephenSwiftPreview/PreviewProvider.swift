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
        
        // Ignore .DS_Store files to avoid displaying system metadata
        if fileURL.lastPathComponent == ".DS_Store" {
            throw PreviewError.unsupportedFile
        }
        
        // Analyze file to determine if it's text and detect encoding
        let analysisResult = try FileAnalyzer.analyze(fileURL: fileURL)
        
        guard analysisResult.isTextFile else {
            throw PreviewError.notTextFile
        }
        
        // Get max file size from user defaults (may truncate large files)
        let maxFileSize = getMaxFileSize()
        
        // Get formatting settings (line numbers, RTF, fonts, colors, etc.)
        let settings = getFormattingSettings()
        
        // Get markdown settings
        let markdownSettings = getMarkdownSettings(formattingSettings: settings)
        
        // Get file size for truncation decision
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int else {
            throw PreviewError.cannotReadFile
        }
        
        // Read file data (respecting maxFileSize limit)
        let data: Data
        if fileSize > maxFileSize {
            // Read only up to maxFileSize
            guard let fileHandle = try? FileHandle(forReadingFrom: fileURL),
                  let limitedData = try? fileHandle.read(upToCount: maxFileSize) else {
                throw PreviewError.cannotReadFile
            }
            try? fileHandle.close()
            data = limitedData
        } else {
            // Read entire file for files within size limit
            guard let fileData = try? Data(contentsOf: fileURL) else {
                throw PreviewError.cannotReadFile
            }
            data = fileData
        }
        
        // Decode text using detected encoding
        let decodedText = String(data: data, encoding: analysisResult.encoding)
        
        // Check if markdown preview should be rendered
        let isMarkdown = markdownSettings.enabled && MarkdownRenderer.isMarkdown(fileURL: fileURL, sampleText: decodedText)
        
        if isMarkdown, let text = decodedText {
            let htmlContent = MarkdownRenderer.renderHTML(markdown: text, with: markdownSettings)
            let reply = QLPreviewReply(dataOfContentType: .html, contentSize: .zero) { reply in
                reply.stringEncoding = .utf8
                return htmlContent.data(using: .utf8) ?? Data()
            }
            return reply
        }
        
        // Determine content type based on RTF rendering setting
        // RTF allows styled output with fonts and colors
        let contentType: UTType
        if settings.rtfRenderingEnabled {
            contentType = UTType.rtf
        } else {
            contentType = UTType.plainText
        }
        
        let reply = QLPreviewReply(dataOfContentType: contentType, contentSize: .zero) { reply in
            // If line numbers or RTF rendering are enabled, format the text
            if settings.lineNumbersEnabled || settings.rtfRenderingEnabled {
                // Decode the text using detected encoding
                guard let text = decodedText else {
                    // Fallback: return original data if decoding fails
                    reply.stringEncoding = analysisResult.encoding
                    return data
                }
                
                // Format the text with line numbers and/or RTF
                if let formattedData = TextFormatter.format(text: text, with: settings) {
                    // For RTF, don't set stringEncoding (RTF has its own encoding)
                    // For plain text with line numbers, use UTF-8
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
                // Original behavior: return raw data with detected encoding
                // No formatting, no line numbers, preserves original encoding
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
            contentForegroundColorDark: AppConstants.RTF.defaultContentForegroundColorDark,
            contentBackgroundColorDark: AppConstants.RTF.defaultContentBackgroundColorDark,
            tabWidthMode: AppConstants.RTF.defaultTabWidthMode,
            tabWidthValue: AppConstants.RTF.defaultTabWidthValue
        )
    }
    
    /// Retrieves Markdown preview settings from shared storage
    /// - Parameter formattingSettings: The current text formatting settings (for line numbers)
    /// - Returns: MarkdownRenderer settings
    private func getMarkdownSettings(formattingSettings: TextFormatter.Settings) -> MarkdownRenderer.Settings {
        if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            let enabled = sharedDefaults.object(forKey: AppConstants.Markdown.enabledKey) != nil
                ? sharedDefaults.bool(forKey: AppConstants.Markdown.enabledKey)
                : AppConstants.Markdown.defaultEnabled
            let defaultView = sharedDefaults.string(forKey: AppConstants.Markdown.defaultViewKey)
                ?? AppConstants.Markdown.defaultViewMode
            return MarkdownRenderer.Settings(
                enabled: enabled,
                defaultView: defaultView,
                lineNumbersEnabled: formattingSettings.lineNumbersEnabled,
                lineSeparator: formattingSettings.lineSeparator
            )
        }
        
        return MarkdownRenderer.Settings(
            enabled: AppConstants.Markdown.defaultEnabled,
            defaultView: AppConstants.Markdown.defaultViewMode,
            lineNumbersEnabled: formattingSettings.lineNumbersEnabled,
            lineSeparator: formattingSettings.lineSeparator
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
