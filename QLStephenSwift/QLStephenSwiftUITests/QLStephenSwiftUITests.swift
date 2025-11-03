//
//  QLStephenSwiftUITests.swift
//  QLStephenSwiftUITests
//
//  Created by Takashi Mochizuki on 2025/10/29.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import XCTest

final class QLStephenSwiftUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testRTFToggleDependsOnLineNumbers() throws {
        // Test that the RTF Output toggle is disabled when Line Numbers are disabled
        let app = XCUIApplication()
        app.launch()
        
        // Find the toggles
        let lineNumbersToggle = app.switches["Show Line Numbers:"]
        let rtfToggle = app.switches["Enable RTF Output:"]
        
        // Ensure line numbers toggle exists
        XCTAssertTrue(lineNumbersToggle.exists, "Line Numbers toggle should exist")
        
        // Ensure RTF toggle exists
        XCTAssertTrue(rtfToggle.exists, "RTF toggle should exist")
        
        // If line numbers are enabled, turn them off
        if lineNumbersToggle.value as? String == "1" {
            lineNumbersToggle.tap()
        }
        
        // Verify that when line numbers are off, RTF toggle is disabled (grayed out)
        XCTAssertFalse(rtfToggle.isEnabled, "RTF toggle should be disabled when line numbers are off")
        
        // Enable line numbers
        lineNumbersToggle.tap()
        
        // Verify that when line numbers are on, RTF toggle is enabled
        XCTAssertTrue(rtfToggle.isEnabled, "RTF toggle should be enabled when line numbers are on")
        
        // Disable line numbers again
        lineNumbersToggle.tap()
        
        // Verify RTF toggle remains disabled (grayed out) when line numbers are off
        XCTAssertFalse(rtfToggle.isEnabled, "RTF toggle should remain disabled when line numbers are off")
    }
}
