//
//  RTFGenerator.swift
//  QLStephenSwiftPreview
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import AppKit

/// Generates RTF (Rich Text Format) output with line numbers and custom formatting
struct RTFGenerator {
    
    /// Converts a hex color string to NSColor
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000")
    /// - Returns: NSColor instance, or black if parsing fails
    static func colorFromHex(_ hex: String) -> NSColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return NSColor.black
        }
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        return NSColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    /// Creates an NSAttributedString with line numbers and formatting
    /// - Parameters:
    ///   - text: The text content
    ///   - settings: Text rendering settings
    ///   - encoding: The text encoding used
    /// - Returns: NSAttributedString with formatting applied
    static func generateAttributedString(
        text: String,
        settings: TextRenderingSettings,
        encoding: String.Encoding
    ) -> NSAttributedString {
        let lines = text.components(separatedBy: .newlines)
        let digitWidth = LineNumberFormatter.calculateDigitWidth(lineCount: lines.count)
        
        let result = NSMutableAttributedString()
        
        // Setup fonts
        let lineNumberFont = NSFont(name: settings.lineNumberFontName, size: settings.lineNumberFontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.lineNumberFontSize, weight: .regular)
        let contentFont = NSFont(name: settings.contentFontName, size: settings.contentFontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.contentFontSize, weight: .regular)
        
        // Setup colors
        let lineNumberTextColor = colorFromHex(settings.lineNumberTextColor)
        let lineNumberBackgroundColor = colorFromHex(settings.lineNumberBackgroundColor)
        let contentTextColor = colorFromHex(settings.contentTextColor)
        let contentBackgroundColor = colorFromHex(settings.contentBackgroundColor)
        
        // Setup paragraph style with tab stops
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Calculate tab width based on mode
        let tabWidth: CGFloat
        if settings.tabWidthMode == .characters {
            // Calculate width of a single character in the content font
            let charWidth = ("M" as NSString).size(withAttributes: [.font: contentFont]).width
            tabWidth = charWidth * settings.tabWidthValue
        } else {
            // Use points directly
            tabWidth = settings.tabWidthValue
        }
        
        // Set default tab interval
        paragraphStyle.defaultTabInterval = tabWidth
        
        // Set tab stops at regular intervals
        let maxTabStops = 50 // Maximum number of tab stops to create
        var tabStops: [NSTextTab] = []
        for i in 1...maxTabStops {
            let location = tabWidth * CGFloat(i)
            tabStops.append(NSTextTab(textAlignment: .left, location: location, options: [:]))
        }
        paragraphStyle.tabStops = tabStops
        
        // Process each line
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            if settings.lineNumbersEnabled {
                // Add line number
                let formattedNumber = LineNumberFormatter.formatLineNumber(lineNumber, totalDigits: digitWidth)
                let lineNumberString = formattedNumber + settings.lineSeparator
                let lineNumberAttr = NSAttributedString(
                    string: lineNumberString,
                    attributes: [
                        .font: lineNumberFont,
                        .foregroundColor: lineNumberTextColor,
                        .backgroundColor: lineNumberBackgroundColor
                    ]
                )
                result.append(lineNumberAttr)
            }
            
            // Add content line
            let contentAttr = NSAttributedString(
                string: line,
                attributes: [
                    .font: contentFont,
                    .foregroundColor: contentTextColor,
                    .backgroundColor: contentBackgroundColor,
                    .paragraphStyle: paragraphStyle
                ]
            )
            result.append(contentAttr)
            
            // Add newline (except for last line)
            if index < lines.count - 1 {
                let newlineAttr = NSAttributedString(
                    string: "\n",
                    attributes: [
                        .font: contentFont,
                        .foregroundColor: contentTextColor,
                        .backgroundColor: contentBackgroundColor
                    ]
                )
                result.append(newlineAttr)
            }
        }
        
        return result
    }
    
    /// Generates RTF data from text with line numbers
    /// - Parameters:
    ///   - text: The text content
    ///   - settings: Text rendering settings
    ///   - encoding: The text encoding used
    /// - Returns: RTF data, or nil if generation fails
    static func generateRTF(
        text: String,
        settings: TextRenderingSettings,
        encoding: String.Encoding
    ) -> Data? {
        let attributedString = generateAttributedString(text: text, settings: settings, encoding: encoding)
        
        // Convert to RTF
        let range = NSRange(location: 0, length: attributedString.length)
        do {
            let rtfData = try attributedString.data(
                from: range,
                documentAttributes: [
                    .documentType: NSAttributedString.DocumentType.rtf
                ]
            )
            return rtfData
        } catch {
            return nil
        }
    }
}
