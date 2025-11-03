//
//  LineNumberFormatterTests.swift
//  QLStephenSwiftTests
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import XCTest

// Note: Since LineNumberFormatter is in the QLStephenSwiftPreview target,
// we need to duplicate the implementation here for testing purposes.
// In a production setting, you would make it a shared framework or add it to the main app target.

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

final class LineNumberFormatterTests: XCTestCase {
    
    func testCalculateDigitWidth_SmallLineCount() {
        // Test with line count less than 4 digits
        XCTAssertEqual(LineNumberFormatter.calculateDigitWidth(lineCount: 1), 4)
        XCTAssertEqual(LineNumberFormatter.calculateDigitWidth(lineCount: 99), 4)
        XCTAssertEqual(LineNumberFormatter.calculateDigitWidth(lineCount: 999), 4)
        XCTAssertEqual(LineNumberFormatter.calculateDigitWidth(lineCount: 9999), 4)
    }
    
    func testCalculateDigitWidth_LargeLineCount() {
        // Test with line count requiring more than 4 digits
        XCTAssertEqual(LineNumberFormatter.calculateDigitWidth(lineCount: 10000), 5)
        XCTAssertEqual(LineNumberFormatter.calculateDigitWidth(lineCount: 99999), 5)
        XCTAssertEqual(LineNumberFormatter.calculateDigitWidth(lineCount: 100000), 6)
    }
    
    func testFormatLineNumber_FourDigitPadding() {
        // Test zero-padding with 4 digits
        XCTAssertEqual(LineNumberFormatter.formatLineNumber(1, totalDigits: 4), "0001")
        XCTAssertEqual(LineNumberFormatter.formatLineNumber(10, totalDigits: 4), "0010")
        XCTAssertEqual(LineNumberFormatter.formatLineNumber(100, totalDigits: 4), "0100")
        XCTAssertEqual(LineNumberFormatter.formatLineNumber(1000, totalDigits: 4), "1000")
    }
    
    func testFormatLineNumber_FiveDigitPadding() {
        // Test zero-padding with 5 digits
        XCTAssertEqual(LineNumberFormatter.formatLineNumber(1, totalDigits: 5), "00001")
        XCTAssertEqual(LineNumberFormatter.formatLineNumber(10000, totalDigits: 5), "10000")
    }
    
    func testAddLineNumbers_SingleLine() {
        let text = "Hello, World!"
        let result = LineNumberFormatter.addLineNumbers(to: text, separator: " | ")
        XCTAssertEqual(result, "0001 | Hello, World!")
    }
    
    func testAddLineNumbers_MultipleLines() {
        let text = "Line 1\nLine 2\nLine 3"
        let result = LineNumberFormatter.addLineNumbers(to: text, separator: " | ")
        let expected = "0001 | Line 1\n0002 | Line 2\n0003 | Line 3"
        XCTAssertEqual(result, expected)
    }
    
    func testAddLineNumbers_CustomSeparator() {
        let text = "Line 1\nLine 2"
        let result = LineNumberFormatter.addLineNumbers(to: text, separator: ": ")
        let expected = "0001: Line 1\n0002: Line 2"
        XCTAssertEqual(result, expected)
    }
    
    func testAddLineNumbers_EmptyLines() {
        let text = "Line 1\n\nLine 3"
        let result = LineNumberFormatter.addLineNumbers(to: text, separator: " | ")
        let expected = "0001 | Line 1\n0002 | \n0003 | Line 3"
        XCTAssertEqual(result, expected)
    }
    
    func testAddLineNumbers_ManyLines() {
        // Test with more than 9999 lines to ensure 5-digit padding
        let lines = (1...10000).map { "Line \($0)" }
        let text = lines.joined(separator: "\n")
        let result = LineNumberFormatter.addLineNumbers(to: text, separator: " | ")
        
        // Check first line
        XCTAssertTrue(result.hasPrefix("00001 | Line 1\n"))
        
        // Check last line
        XCTAssertTrue(result.hasSuffix("10000 | Line 10000"))
        
        // Check a middle line
        XCTAssertTrue(result.contains("05000 | Line 5000"))
    }
}
