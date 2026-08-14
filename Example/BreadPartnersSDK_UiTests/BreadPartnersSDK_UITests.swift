//
//  BreadPartnersSDK_UITests.swift
//  BreadPartnersSDK_UITests
//
//  Created by Kyle Banks on 8/14/26.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import XCTest

final class BreadPartnersSDK_UITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeScreenShowsPrimarySDKEntryPoints() throws {
        XCTAssertTrue(app.buttons["OpenExperience"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["RTPS"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testRTPSFlowShowsCheckoutSummary() throws {
        let rtpsButton = app.buttons["RTPS"]
        XCTAssertTrue(rtpsButton.waitForExistence(timeout: 5))
        rtpsButton.tap()

        XCTAssertTrue(app.staticTexts["Checkout"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Product Price"].exists)
        XCTAssertTrue(app.staticTexts["Total: $49.99"].exists)
    }
}
