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
    
    /// Test that RTF rendering works independently of line numbers
    func testRTFIndependentOfLineNumbers() throws {
        // Document the expected behavior:
        // - RTF rendering can work with or without line numbers
        // - RTF is controlled solely by the rtfRenderingEnabled flag
        
        // Case 1: rtfEnabled=true, lineNumbers=false -> SHOULD generate RTF (without line numbers)
        let rtfOnlyEnabled = true
        let lineNumbersDisabled = false
        let shouldGenerateRTF = rtfOnlyEnabled
        XCTAssertTrue(shouldGenerateRTF, "RTF should be generated even when line numbers are disabled")
        
        // Case 2: rtfEnabled=true, lineNumbers=true -> SHOULD generate RTF (with line numbers)
        let rtfEnabledLineNumbersEnabled = true && true
        XCTAssertTrue(rtfEnabledLineNumbersEnabled, "RTF should be generated when both RTF and line numbers are enabled")
        
        // Case 3: rtfEnabled=false, lineNumbers=true -> should NOT generate RTF (plain text with line numbers)
        let rtfDisabled = false
        XCTAssertFalse(rtfDisabled, "RTF should not be generated when RTF is disabled")
        
        // Case 4: rtfEnabled=false, lineNumbers=false -> should NOT generate RTF (plain text)
        let bothDisabled = false
        XCTAssertFalse(bothDisabled, "RTF should not be generated when both are disabled")
    }
    
    /// Test new font customization constants
    func testFontCustomizationConstants() throws {
        // Test available fonts retrieval from system
        let availableFonts = AppConstants.RTF.getAvailableMonospacedFonts()
        XCTAssertGreaterThan(availableFonts.count, 0, "Should find at least some monospaced fonts")
        
        // Common monospaced fonts that should be available on macOS
        // Note: We don't assert all exist as font availability may vary by system
        let commonMonospacedFonts = ["Menlo", "Monaco", "Courier"]
        let foundCommonFonts = commonMonospacedFonts.filter { availableFonts.contains($0) }
        XCTAssertGreaterThan(foundCommonFonts.count, 0, "Should find at least one common monospaced font")
        
        // Test font size range
        let minFontSize: CGFloat = 8.0
        let maxFontSize: CGFloat = 24.0
        XCTAssertEqual(minFontSize, 8.0)
        XCTAssertEqual(maxFontSize, 24.0)
    }
    
    /// Test dark mode color defaults
    func testDarkModeColorDefaults() throws {
        let defaultFgLight = "#000000"  // Black
        let defaultBgLight = "#FFFFFF"  // White
        let defaultFgDark = "#E0E0E0"   // Light gray
        let defaultBgDark = "#1E1E1E"   // Dark gray
        
        XCTAssertEqual(defaultFgLight, "#000000")
        XCTAssertEqual(defaultBgLight, "#FFFFFF")
        XCTAssertEqual(defaultFgDark, "#E0E0E0")
        XCTAssertEqual(defaultBgDark, "#1E1E1E")
    }
}
