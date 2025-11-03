//
//  AttributedTextRenderer.swift
//  QLStephenSwiftPreview
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation
import AppKit

/// Renderer for creating attributed strings with line numbers and custom formatting
struct AttributedTextRenderer {
    
    /// Renders text content as an NSAttributedString with optional line numbers
    /// - Parameters:
    ///   - text: The text content to render
    ///   - settings: Formatting settings including line numbers and font attributes
    /// - Returns: An attributed string ready for RTF output
    static func render(text: String, settings: TextFormattingSettings) -> NSAttributedString {
        if settings.lineNumbersEnabled {
            return renderWithLineNumbers(text: text, settings: settings)
        } else {
            return renderPlainText(text: text, settings: settings)
        }
    }
    
    /// Renders text without line numbers
    private static func renderPlainText(text: String, settings: TextFormattingSettings) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Get font
        let font = NSFont(name: settings.contentFont.fontName, size: settings.contentFont.fontSize) ??
                   NSFont.monospacedSystemFont(ofSize: settings.contentFont.fontSize, weight: .regular)
        
        // Create paragraph style with tab stops
        let paragraphStyle = createParagraphStyle(font: font, settings: settings)
        
        // Apply attributes
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: settings.contentFont.textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        if let backgroundColor = settings.contentFont.backgroundColor {
            attributes[.backgroundColor] = backgroundColor
        }
        
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
        
        return attributedString
    }
    
    /// Renders text with line numbers
    private static func renderWithLineNumbers(text: String, settings: TextFormattingSettings) -> NSAttributedString {
        let lines = text.components(separatedBy: .newlines)
        let lineCount = lines.count
        
        // Calculate line number width (minimum 4 digits)
        let digitCount = max(4, String(lineCount).count)
        
        // Get fonts
        let lineNumberFont = NSFont(name: settings.lineNumberFont.fontName, 
                                   size: settings.lineNumberFont.fontSize) ??
                            NSFont.monospacedSystemFont(ofSize: settings.lineNumberFont.fontSize, weight: .regular)
        
        let contentFont = NSFont(name: settings.contentFont.fontName,
                                size: settings.contentFont.fontSize) ??
                         NSFont.monospacedSystemFont(ofSize: settings.contentFont.fontSize, weight: .regular)
        
        // Create paragraph style
        let paragraphStyle = createParagraphStyle(font: contentFont, settings: settings)
        
        // Build attributed string
        let result = NSMutableAttributedString()
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            // Format line number with zero padding
            let lineNumberString = String(format: "%0*d", digitCount, lineNumber)
            
            // Add line number with its attributes
            let lineNumberAttributed = NSAttributedString(
                string: lineNumberString,
                attributes: createLineNumberAttributes(font: lineNumberFont, settings: settings)
            )
            result.append(lineNumberAttributed)
            
            // Add separator
            let separator = resolveSeparator(settings.lineSeparator)
            let separatorAttributed = NSAttributedString(
                string: separator,
                attributes: createLineNumberAttributes(font: lineNumberFont, settings: settings)
            )
            result.append(separatorAttributed)
            
            // Add content line
            var contentAttributes = createContentAttributes(font: contentFont, paragraphStyle: paragraphStyle, settings: settings)
            let contentAttributed = NSAttributedString(
                string: line,
                attributes: contentAttributes
            )
            result.append(contentAttributed)
            
            // Add newline (except for last line if it doesn't end with one)
            if index < lines.count - 1 || text.hasSuffix("\n") {
                result.append(NSAttributedString(string: "\n", attributes: contentAttributes))
            }
        }
        
        return result
    }
    
    /// Creates attributes dictionary for line numbers
    private static func createLineNumberAttributes(font: NSFont, settings: TextFormattingSettings) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: settings.lineNumberFont.textColor
        ]
        
        if let backgroundColor = settings.lineNumberFont.backgroundColor {
            attributes[.backgroundColor] = backgroundColor
        }
        
        return attributes
    }
    
    /// Creates attributes dictionary for content text
    private static func createContentAttributes(font: NSFont, 
                                               paragraphStyle: NSParagraphStyle,
                                               settings: TextFormattingSettings) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: settings.contentFont.textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        if let backgroundColor = settings.contentFont.backgroundColor {
            attributes[.backgroundColor] = backgroundColor
        }
        
        return attributes
    }
    
    /// Creates paragraph style with tab stops based on settings
    private static func createParagraphStyle(font: NSFont, settings: TextFormattingSettings) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Calculate tab width
        let tabWidth: CGFloat
        switch settings.tabWidth.mode {
        case .characters:
            // Calculate width of one character in the font using a more modern approach
            // Use 'm' character as reference for monospace width
            let mString = "m" as NSString
            let size = mString.size(withAttributes: [.font: font])
            let characterWidth = size.width
            tabWidth = characterWidth * settings.tabWidth.value
        case .points:
            tabWidth = settings.tabWidth.value
        }
        
        // Set default tab interval
        paragraphStyle.defaultTabInterval = tabWidth
        
        // Create tab stops at regular intervals
        var tabStops: [NSTextTab] = []
        for i in 1...100 {  // Create 100 tab stops
            let location = tabWidth * CGFloat(i)
            tabStops.append(NSTextTab(type: .leftTabStopType, location: location))
        }
        paragraphStyle.tabStops = tabStops
        
        return paragraphStyle
    }
    
    /// Resolves separator string from setting
    private static func resolveSeparator(_ separator: String) -> String {
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
    
    /// Calculates the number of lines in text
    static func lineCount(in text: String) -> Int {
        return text.components(separatedBy: .newlines).count
    }
    
    /// Calculates the required digit count for line numbers
    static func digitCount(for lineCount: Int) -> Int {
        return max(4, String(lineCount).count)
    }
}
