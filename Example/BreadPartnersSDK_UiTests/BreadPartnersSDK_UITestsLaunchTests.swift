//
//  BreadPartnersSDK_UITestsLaunchTests.swift
//  BreadPartnersSDK_UITests
//
//  Created by Kyle Banks on 8/14/26.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import XCTest

final class BreadPartnersSDK_UITestsLaunchTests: XCTestCase {

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
    func testOpenExperienceFlowNavigatesAwayFromHomeScreen() throws {
        let openExperienceButton = app.buttons["OpenExperience"]
        XCTAssertTrue(openExperienceButton.waitForExistence(timeout: 5))

        openExperienceButton.tap()

        // Basic smoke assertion: tapping OpenExperience does not crash the host app.
        XCTAssertEqual(app.state, .runningForeground)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "OpenExperience Smoke"
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
}
