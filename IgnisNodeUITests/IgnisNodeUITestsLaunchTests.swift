//
//  IgnisNodeUITestsLaunchTests.swift
//  IgnisNodeUITests
//
//  Created by PRABAL PATRA on 04/04/26.
//

import XCTest

final class IgnisNodeUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        let app = XCUIApplication()
        if app.state == .runningForeground || app.state == .runningBackground {
            app.terminate()
        }
    }

    func testLaunch() {
        let app = IgnisUITestSupport.applicationUnderTest()
        app.launch()

        let brand = IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeBrandTitle)
        XCTAssertTrue(brand.waitForExistence(timeout: IgnisUITestSupport.homeShellTimeout))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
