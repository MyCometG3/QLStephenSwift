//
//  TextFormatter.swift
//  QLStephenSwiftPreview
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import AppKit

/// Handles text formatting with line numbers and RTF rendering
struct TextFormatter {
    
    /// Settings for text formatting
    struct Settings {
        let lineNumbersEnabled: Bool
        let lineSeparator: String
        let rtfRenderingEnabled: Bool
        
        // Line number font settings
        let lineNumberFontName: String
        let lineNumberFontSize: CGFloat
        let lineNumberForegroundColor: String
        let lineNumberBackgroundColor: String
        
        // Content font settings
        let contentFontName: String
        let contentFontSize: CGFloat
        let contentForegroundColor: String
        let contentBackgroundColor: String
        
        // Tab width settings
        let tabWidthMode: String
        let tabWidthValue: Double
        
        /// Load settings from UserDefaults
        static func load(from defaults: UserDefaults) -> Settings {
            // Read font sizes once and use default if zero
            let lineNumberFontSizeValue = defaults.double(forKey: AppConstants.RTF.lineNumberFontSizeKey)
            let lineNumberFontSize = lineNumberFontSizeValue != 0 ? CGFloat(lineNumberFontSizeValue) : AppConstants.RTF.defaultLineNumberFontSize
            
            let contentFontSizeValue = defaults.double(forKey: AppConstants.RTF.contentFontSizeKey)
            let contentFontSize = contentFontSizeValue != 0 ? CGFloat(contentFontSizeValue) : AppConstants.RTF.defaultContentFontSize
            
            let tabWidthValueValue = defaults.double(forKey: AppConstants.RTF.tabWidthValueKey)
            let tabWidthValue = tabWidthValueValue != 0 ? tabWidthValueValue : AppConstants.RTF.defaultTabWidthValue
            
            return Settings(
                lineNumbersEnabled: defaults.bool(forKey: AppConstants.LineNumbers.enabledKey),
                lineSeparator: defaults.string(forKey: AppConstants.LineNumbers.separatorKey) ?? AppConstants.LineNumbers.defaultSeparator,
                rtfRenderingEnabled: defaults.bool(forKey: AppConstants.RTF.enabledKey),
                lineNumberFontName: defaults.string(forKey: AppConstants.RTF.lineNumberFontNameKey) ?? AppConstants.RTF.defaultLineNumberFontName,
                lineNumberFontSize: lineNumberFontSize,
                lineNumberForegroundColor: defaults.string(forKey: AppConstants.RTF.lineNumberForegroundColorKey) ?? AppConstants.RTF.defaultLineNumberForegroundColor,
                lineNumberBackgroundColor: defaults.string(forKey: AppConstants.RTF.lineNumberBackgroundColorKey) ?? AppConstants.RTF.defaultLineNumberBackgroundColor,
                contentFontName: defaults.string(forKey: AppConstants.RTF.contentFontNameKey) ?? AppConstants.RTF.defaultContentFontName,
                contentFontSize: contentFontSize,
                contentForegroundColor: defaults.string(forKey: AppConstants.RTF.contentForegroundColorKey) ?? AppConstants.RTF.defaultContentForegroundColor,
                contentBackgroundColor: defaults.string(forKey: AppConstants.RTF.contentBackgroundColorKey) ?? AppConstants.RTF.defaultContentBackgroundColor,
                tabWidthMode: defaults.string(forKey: AppConstants.RTF.tabWidthModeKey) ?? AppConstants.RTF.defaultTabWidthMode,
                tabWidthValue: tabWidthValue
            )
        }
    }
    
    /// Format text with optional line numbers and RTF rendering
    /// - Parameters:
    ///   - text: The text content to format
    ///   - settings: Formatting settings
    /// - Returns: Formatted text or NSAttributedString data (RTF)
    static func format(text: String, with settings: Settings) -> Data? {
        // If neither line numbers nor RTF are enabled, return original text as plain data
        guard settings.lineNumbersEnabled || settings.rtfRenderingEnabled else {
            return text.data(using: .utf8)
        }
        
        // If line numbers are enabled but RTF is not, return plain text with line numbers
        if settings.lineNumbersEnabled && !settings.rtfRenderingEnabled {
            let textWithLineNumbers = addLineNumbers(to: text, separator: settings.lineSeparator)
            return textWithLineNumbers.data(using: .utf8)
        }
        
        // If RTF is enabled, create attributed string
        if settings.rtfRenderingEnabled {
            let attributedString = createAttributedString(
                from: text,
                settings: settings
            )
            
            // Convert to RTF data
            let range = NSRange(location: 0, length: attributedString.length)
            do {
                let rtfData = try attributedString.data(
                    from: range,
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
                return rtfData
            } catch {
                // Fallback to plain text if RTF generation fails
                return text.data(using: .utf8)
            }
        }
        
        return text.data(using: .utf8)
    }
    
    /// Add line numbers to text
    private static func addLineNumbers(to text: String, separator: String) -> String {
        // Split on line breaks while preserving line structure
        // This handles LF, CR, and CRLF correctly without creating empty elements
        // Match CRLF first, then LF, then CR to avoid splitting CRLF into CR + LF
        let lines = text.split(separator: /\r\n|\n|\r/, omittingEmptySubsequences: false).map(String.init)
        let lineCount = lines.count
        let digitWidth = max(AppConstants.LineNumbers.minDigits, String(lineCount).count)
        
        // Use array and join for better performance with large files
        var numberedLines: [String] = []
        numberedLines.reserveCapacity(lineCount)
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let paddedNumber = String(format: "%0\(digitWidth)d", lineNumber)
            numberedLines.append("\(paddedNumber)\(separator)\(line)")
        }
        
        var result = numberedLines.joined(separator: "\n")
        
        // Add trailing newline if original text had one (\n, \r, or \r\n)
        if text.hasSuffix("\r\n") {
            result.append("\r\n")
        } else if text.hasSuffix("\n") {
            result.append("\n")
        } else if text.hasSuffix("\r") {
            result.append("\r")
        }
        
        return result
    }
    
    /// Create attributed string with formatting
    private static func createAttributedString(from text: String, settings: Settings) -> NSAttributedString {
        // Split on line breaks while preserving line structure
        // This handles LF, CR, and CRLF correctly without creating empty elements
        // Match CRLF first, then LF, then CR to avoid splitting CRLF into CR + LF
        let lines = text.split(separator: /\r\n|\n|\r/, omittingEmptySubsequences: false).map(String.init)
        let lineCount = lines.count
        let digitWidth = settings.lineNumbersEnabled ? max(AppConstants.LineNumbers.minDigits, String(lineCount).count) : 0
        
        // Create fonts
        let lineNumberFont = NSFont(name: settings.lineNumberFontName, size: settings.lineNumberFontSize) ?? NSFont.monospacedSystemFont(ofSize: settings.lineNumberFontSize, weight: .regular)
        let contentFont = NSFont(name: settings.contentFontName, size: settings.contentFontSize) ?? NSFont.monospacedSystemFont(ofSize: settings.contentFontSize, weight: .regular)
        
        // Create colors
        let lineNumberFgColor = colorFromHex(settings.lineNumberForegroundColor) ?? NSColor.gray
        let lineNumberBgColor = colorFromHex(settings.lineNumberBackgroundColor) ?? NSColor.lightGray.withAlphaComponent(0.3)
        let contentFgColor = colorFromHex(settings.contentForegroundColor) ?? NSColor.black
        let contentBgColor = colorFromHex(settings.contentBackgroundColor) ?? NSColor.white
        
        // Create paragraph style with tab stops
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Configure tab width
        if settings.tabWidthMode == AppConstants.RTF.TabWidthMode.characters.rawValue {
            // Calculate tab width in points based on character width using NSString.size(withAttributes:)
            let charWidth = ("m" as NSString).size(withAttributes: [.font: contentFont]).width
            let tabWidth = charWidth * CGFloat(settings.tabWidthValue)
            paragraphStyle.defaultTabInterval = tabWidth
        } else {
            // Use points directly
            paragraphStyle.defaultTabInterval = CGFloat(settings.tabWidthValue)
        }
        
        // If line numbers are enabled and separator is a tab, set an explicit first tab stop so the first tab aligns
        if settings.lineNumbersEnabled && settings.lineSeparator == "\t" {
            // Calculate width of the line number area (digitWidth zeros) using NSString sizing
            let digitString = String(repeating: "0", count: digitWidth)
            let numberAreaWidth = (digitString as NSString).size(withAttributes: [.font: lineNumberFont]).width
            let padding: CGFloat = 12.0 // small padding between numbers and content
            let firstTabLocation = numberAreaWidth + padding
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: firstTabLocation)]
        }
        
        // Line number attributes (do not include paragraphStyle here)
        // Paragraph style will be applied to the whole paragraph range after it is built
        let lineNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: lineNumberFont,
            .foregroundColor: lineNumberFgColor,
            .backgroundColor: lineNumberBgColor
        ]
        
        // Content attributes (do not include paragraphStyle here)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: contentFgColor,
            .backgroundColor: contentBgColor
        ]
        
        let result = NSMutableAttributedString()
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            // Track paragraph start index so we can apply paragraphStyle to the full paragraph after building it
            let paragraphStart = result.length
            
            // Add line number if enabled
            if settings.lineNumbersEnabled {
                let paddedNumber = String(format: "%0\(digitWidth)d", lineNumber)
                let lineNumberString = NSAttributedString(string: paddedNumber, attributes: lineNumberAttributes)
                result.append(lineNumberString)
                
                // For tab separator, use content attributes so it respects tab stops
                // For other separators, use line number attributes
                let separatorAttributes = (settings.lineSeparator == "\t") ? contentAttributes : lineNumberAttributes
                let separatorString = NSAttributedString(string: settings.lineSeparator, attributes: separatorAttributes)
                result.append(separatorString)
            }
            
            // Add content
            let contentString = NSAttributedString(string: line, attributes: contentAttributes)
            result.append(contentString)
            
            // Add newline except for last line (if original didn't have trailing newline)
            if index < lines.count - 1 || text.hasSuffix("\n") || text.hasSuffix("\r") {
                let newlineString = NSAttributedString(string: "\n", attributes: contentAttributes)
                result.append(newlineString)
            }
            
            // Apply paragraphStyle to the entire paragraph that was just appended
            let paragraphLength = result.length - paragraphStart
            if paragraphLength > 0 {
                result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: paragraphStart, length: paragraphLength))
            }
        }
        
        return result
    }
    
    /// Convert hex color string to NSColor
    private static func colorFromHex(_ hex: String) -> NSColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        let r, g, b, a: CGFloat
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
}
