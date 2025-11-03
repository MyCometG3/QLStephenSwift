//
//  LineNumberFormatter.swift
//  QLStephenSwiftPreview
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation

/// Utilities for formatting line numbers in text preview
struct LineNumberFormatter {
    
    /// Calculates the number of digits needed to display line numbers
    /// - Parameter lineCount: Total number of lines
    /// - Returns: Number of digits (minimum 4)
    static func calculateDigitWidth(lineCount: Int) -> Int {
        let actualDigits = String(lineCount).count
        return max(4, actualDigits)
    }
    
    /// Formats a line number with zero-padding
    /// - Parameters:
    ///   - lineNumber: The line number to format (1-indexed)
    ///   - totalDigits: Total number of digits for padding
    /// - Returns: Zero-padded line number string
    static func formatLineNumber(_ lineNumber: Int, totalDigits: Int) -> String {
        let numberString = String(lineNumber)
        let paddingCount = max(0, totalDigits - numberString.count)
        let padding = String(repeating: "0", count: paddingCount)
        return padding + numberString
    }
    
    /// Adds line numbers to text content
    /// - Parameters:
    ///   - text: The text content to add line numbers to
    ///   - separator: The separator string between line number and content
    /// - Returns: Text with line numbers prepended to each line
    static func addLineNumbers(to text: String, separator: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let digitWidth = calculateDigitWidth(lineCount: lines.count)
        
        let numberedLines = lines.enumerated().map { index, line in
            let lineNumber = index + 1
            let formattedNumber = formatLineNumber(lineNumber, totalDigits: digitWidth)
            return "\(formattedNumber)\(separator)\(line)"
        }
        
        return numberedLines.joined(separator: "\n")
    }
}
