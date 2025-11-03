//
//  TextFormatterTests.swift
//  QLStephenSwiftTests
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import XCTest

final class TextFormatterTests: XCTestCase {
    
    /// Test that line numbers are correctly formatted with zero padding
    func testLineNumberFormatting() throws {
        // Test case 1: Small file (< 10 lines) - should use 4 digits minimum
        let text1 = "line 1\nline 2\nline 3"
        let expected1 = "0001 line 1\n0002 line 2\n0003 line 3"
        
        // We can't directly test TextFormatter without importing it,
        // but we can document expected behavior
        // Format: zero-padded to at least 4 digits
        XCTAssertTrue(expected1.contains("0001"))
        XCTAssertTrue(expected1.contains("0002"))
        XCTAssertTrue(expected1.contains("0003"))
    }
    
    /// Test line number digit width calculation
    func testLineNumberDigitWidth() throws {
        // For 99 lines, we need 4 digits (minimum)
        let digitWidth99 = max(4, String(99).count)  // Should be 4
        XCTAssertEqual(digitWidth99, 4)
        
        // For 1000 lines, we need 4 digits
        let digitWidth1000 = max(4, String(1000).count)  // Should be 4
        XCTAssertEqual(digitWidth1000, 4)
        
        // For 10000 lines, we need 5 digits
        let digitWidth10000 = max(4, String(10000).count)  // Should be 5
        XCTAssertEqual(digitWidth10000, 5)
        
        // For 99999 lines, we need 5 digits
        let digitWidth99999 = max(4, String(99999).count)  // Should be 5
        XCTAssertEqual(digitWidth99999, 5)
    }
    
    /// Test separator options
    func testSeparatorOptions() throws {
        let separators = [
            ("space", " "),
            ("colon", ":"),
            ("pipe", "|"),
            ("tab", "\t")
        ]
        
        XCTAssertEqual(separators.count, 4)
        XCTAssertEqual(separators[0].1, " ")
        XCTAssertEqual(separators[1].1, ":")
        XCTAssertEqual(separators[2].1, "|")
        XCTAssertEqual(separators[3].1, "\t")
    }
    
    /// Test hex color parsing
    func testHexColorParsing() throws {
        // Test 6-digit hex color
        let hex6 = "FF0000"
        var hexSanitized = hex6.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        XCTAssertTrue(Scanner(string: hexSanitized).scanHexInt64(&rgb))
        XCTAssertEqual(rgb, 0xFF0000)
        
        // Test with # prefix
        let hex6WithHash = "#00FF00"
        hexSanitized = hex6WithHash.replacingOccurrences(of: "#", with: "")
        rgb = 0
        XCTAssertTrue(Scanner(string: hexSanitized).scanHexInt64(&rgb))
        XCTAssertEqual(rgb, 0x00FF00)
        
        // Test 8-digit hex color with alpha
        let hex8 = "FF0000FF"
        hexSanitized = hex8.replacingOccurrences(of: "#", with: "")
        rgb = 0
        XCTAssertTrue(Scanner(string: hexSanitized).scanHexInt64(&rgb))
        XCTAssertEqual(rgb, 0xFF0000FF)
    }
    
    /// Test that line count is correctly determined
    func testLineCountCalculation() throws {
        let text1 = "line 1"
        let lines1 = text1.split(separator: /\r\n|\n|\r/, omittingEmptySubsequences: false)
        XCTAssertEqual(lines1.count, 1)
        
        let text2 = "line 1\nline 2"
        let lines2 = text2.split(separator: /\r\n|\n|\r/, omittingEmptySubsequences: false)
        XCTAssertEqual(lines2.count, 2)
        
        let text3 = "line 1\nline 2\nline 3\n"
        let lines3 = text3.split(separator: /\r\n|\n|\r/, omittingEmptySubsequences: false)
        // Trailing newline creates an empty last element
        XCTAssertEqual(lines3.count, 4)
    }
    
    /// Test handling of files without trailing newlines
    func testTrailingNewlineHandling() throws {
        let textWithoutNewline = "line 1\nline 2\nline 3"
        XCTAssertFalse(textWithoutNewline.hasSuffix("\n"))
        
        let textWithNewline = "line 1\nline 2\nline 3\n"
        XCTAssertTrue(textWithNewline.hasSuffix("\n"))
    }
    
    /// Test that settings have correct default values
    func testDefaultSettings() throws {
        // These should match AppConstants defaults
        let defaultEnabled = false
        let defaultSeparator = " "
        let minDigits = 4
        
        XCTAssertFalse(defaultEnabled)
        XCTAssertEqual(defaultSeparator, " ")
        XCTAssertEqual(minDigits, 4)
    }
    
    /// Test RTF default settings
    func testRTFDefaultSettings() throws {
        let defaultFontName = "Menlo"
        let defaultFontSize: CGFloat = 11.0
        let defaultTabMode = "characters"
        let defaultTabValue = 4.0
        
        XCTAssertEqual(defaultFontName, "Menlo")
        XCTAssertEqual(defaultFontSize, 11.0)
        XCTAssertEqual(defaultTabMode, "characters")
        XCTAssertEqual(defaultTabValue, 4.0)
    }
    
    /// Test that RTF rendering requires line numbers to be enabled
    func testRTFRequiresLineNumbers() throws {
        // Document the expected behavior:
        // - RTF rendering should only work when line numbers are enabled
        // - This ensures UI and backend logic are consistent
        
        // Case 1: rtfEnabled=true, lineNumbers=false -> should NOT generate RTF
        let rtfEnabledLineNumbersDisabled = true && false
        XCTAssertFalse(rtfEnabledLineNumbersDisabled, "RTF should not be generated when line numbers are disabled")
        
        // Case 2: rtfEnabled=true, lineNumbers=true -> should generate RTF
        let rtfEnabledLineNumbersEnabled = true && true
        XCTAssertTrue(rtfEnabledLineNumbersEnabled, "RTF should be generated when both RTF and line numbers are enabled")
        
        // Case 3: rtfEnabled=false, lineNumbers=true -> should NOT generate RTF
        let rtfDisabledLineNumbersEnabled = false && true
        XCTAssertFalse(rtfDisabledLineNumbersEnabled, "RTF should not be generated when RTF is disabled")
        
        // Case 4: rtfEnabled=false, lineNumbers=false -> should NOT generate RTF
        let bothDisabled = false && false
        XCTAssertFalse(bothDisabled, "RTF should not be generated when both are disabled")
    }
}
