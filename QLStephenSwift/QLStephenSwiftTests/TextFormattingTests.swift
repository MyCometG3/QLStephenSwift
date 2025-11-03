//
//  TextFormattingTests.swift
//  QLStephenSwiftTests
//
//  Created by GitHub Copilot on 2025/11/03.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import XCTest
@testable import QLStephenSwiftPreview

final class TextFormattingTests: XCTestCase {
    
    // MARK: - Line Number Tests
    
    func testLineCountCalculation() throws {
        let text1 = "line1\nline2\nline3"
        XCTAssertEqual(AttributedTextRenderer.lineCount(in: text1), 3)
        
        let text2 = "single line"
        XCTAssertEqual(AttributedTextRenderer.lineCount(in: text2), 1)
        
        let text3 = ""
        XCTAssertEqual(AttributedTextRenderer.lineCount(in: text3), 1)
        
        let text4 = "line1\nline2\nline3\n"
        XCTAssertEqual(AttributedTextRenderer.lineCount(in: text4), 4)
    }
    
    func testDigitCountCalculation() throws {
        // Test minimum 4 digits
        XCTAssertEqual(AttributedTextRenderer.digitCount(for: 1), 4)
        XCTAssertEqual(AttributedTextRenderer.digitCount(for: 99), 4)
        XCTAssertEqual(AttributedTextRenderer.digitCount(for: 999), 4)
        XCTAssertEqual(AttributedTextRenderer.digitCount(for: 9999), 4)
        
        // Test 5+ digits
        XCTAssertEqual(AttributedTextRenderer.digitCount(for: 10000), 5)
        XCTAssertEqual(AttributedTextRenderer.digitCount(for: 99999), 5)
        XCTAssertEqual(AttributedTextRenderer.digitCount(for: 100000), 6)
    }
    
    func testRenderPlainTextWithoutLineNumbers() throws {
        let text = "Hello\nWorld"
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = false
        
        let result = AttributedTextRenderer.render(text: text, settings: settings)
        
        XCTAssertEqual(result.string, text)
        XCTAssertGreaterThan(result.length, 0)
    }
    
    func testRenderTextWithLineNumbers() throws {
        let text = "line1\nline2\nline3"
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = true
        settings.lineSeparator = " "
        
        let result = AttributedTextRenderer.render(text: text, settings: settings)
        
        // Check that line numbers are present
        XCTAssertTrue(result.string.contains("0001"))
        XCTAssertTrue(result.string.contains("0002"))
        XCTAssertTrue(result.string.contains("0003"))
        
        // Check that original content is present
        XCTAssertTrue(result.string.contains("line1"))
        XCTAssertTrue(result.string.contains("line2"))
        XCTAssertTrue(result.string.contains("line3"))
    }
    
    func testRenderTextWithDifferentSeparators() throws {
        let text = "line1\nline2"
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = true
        
        // Test colon separator
        settings.lineSeparator = ":"
        let result1 = AttributedTextRenderer.render(text: text, settings: settings)
        XCTAssertTrue(result1.string.contains("0001:"))
        
        // Test pipe separator
        settings.lineSeparator = "|"
        let result2 = AttributedTextRenderer.render(text: text, settings: settings)
        XCTAssertTrue(result2.string.contains("0001|"))
        
        // Test tab separator
        settings.lineSeparator = "\t"
        let result3 = AttributedTextRenderer.render(text: text, settings: settings)
        XCTAssertTrue(result3.string.contains("0001\t"))
    }
    
    func testRenderTextWithManyLines() throws {
        // Test that digit count increases appropriately
        var lines: [String] = []
        for i in 1...12345 {
            lines.append("Line \(i)")
        }
        let text = lines.joined(separator: "\n")
        
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = true
        settings.lineSeparator = " "
        
        let result = AttributedTextRenderer.render(text: text, settings: settings)
        
        // Should use 5 digits for line numbers
        XCTAssertTrue(result.string.contains("00001"))
        XCTAssertTrue(result.string.contains("12345"))
        
        // Check intermediate lines
        XCTAssertTrue(result.string.contains("01000"))
        XCTAssertTrue(result.string.contains("10000"))
    }
    
    // MARK: - Settings Tests
    
    func testDefaultSettings() throws {
        let settings = TextFormattingSettings.default
        
        XCTAssertFalse(settings.lineNumbersEnabled)
        XCTAssertFalse(settings.rtfRenderingEnabled)
        XCTAssertEqual(settings.lineSeparator, " ")
        XCTAssertEqual(settings.tabWidth.mode, .characters)
        XCTAssertEqual(settings.tabWidth.value, 4.0)
    }
    
    func testSettingsSaveAndLoad() throws {
        // Create custom settings
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = true
        settings.lineSeparator = ":"
        settings.rtfRenderingEnabled = true
        settings.tabWidth.mode = .points
        settings.tabWidth.value = 20.0
        
        // Save settings
        settings.save()
        
        // Load settings
        let loadedSettings = TextFormattingSettings.load()
        
        // Verify loaded settings match saved settings
        XCTAssertEqual(loadedSettings.lineNumbersEnabled, true)
        XCTAssertEqual(loadedSettings.lineSeparator, ":")
        XCTAssertEqual(loadedSettings.rtfRenderingEnabled, true)
        XCTAssertEqual(loadedSettings.tabWidth.mode, .points)
        XCTAssertEqual(loadedSettings.tabWidth.value, 20.0)
        
        // Clean up - restore defaults
        TextFormattingSettings.default.save()
    }
    
    func testFontAttributes() throws {
        let defaultFont = TextFormattingSettings.FontAttributes.default
        XCTAssertEqual(defaultFont.fontName, "Menlo")
        XCTAssertEqual(defaultFont.fontSize, 11.0)
        
        let lineNumberFont = TextFormattingSettings.FontAttributes.defaultLineNumber
        XCTAssertEqual(lineNumberFont.fontName, "Menlo")
        XCTAssertEqual(lineNumberFont.fontSize, 11.0)
        XCTAssertNotNil(lineNumberFont.backgroundColor)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyText() throws {
        let text = ""
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = true
        
        let result = AttributedTextRenderer.render(text: text, settings: settings)
        
        // Should have at least a line number for the first (empty) line
        XCTAssertGreaterThan(result.length, 0)
    }
    
    func testTextWithOnlyNewlines() throws {
        let text = "\n\n\n"
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = true
        
        let result = AttributedTextRenderer.render(text: text, settings: settings)
        
        // Should have line numbers for all lines
        XCTAssertTrue(result.string.contains("0001"))
        XCTAssertTrue(result.string.contains("0002"))
        XCTAssertTrue(result.string.contains("0003"))
        XCTAssertTrue(result.string.contains("0004"))
    }
    
    func testTextWithTabs() throws {
        let text = "line1\t\ttabbed\nline2"
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = false
        settings.tabWidth.mode = .characters
        settings.tabWidth.value = 4.0
        
        let result = AttributedTextRenderer.render(text: text, settings: settings)
        
        // Verify tabs are preserved in the output
        XCTAssertTrue(result.string.contains("\t"))
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceLargeFile() throws {
        // Generate a large text file (10,000 lines)
        var lines: [String] = []
        for i in 1...10000 {
            lines.append("This is line number \(i) with some content")
        }
        let text = lines.joined(separator: "\n")
        
        var settings = TextFormattingSettings.default
        settings.lineNumbersEnabled = true
        
        measure {
            _ = AttributedTextRenderer.render(text: text, settings: settings)
        }
    }
}
