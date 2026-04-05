//
//  IgnisNodeUITests.swift
//  IgnisNodeUITests
//
//  Created by PRABAL PATRA on 04/04/26.
//

import XCTest

final class IgnisNodeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        let app = XCUIApplication()
        if app.state == .runningForeground || app.state == .runningBackground {
            app.terminate()
        }
    }

    private func homeBrandTitle(in app: XCUIApplication) -> XCUIElement {
        IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeBrandTitle)
    }

    func testHomeSmoke_AllPrimarySectionsVisible() {
        let app = IgnisUITestSupport.applicationUnderTest()
        app.launch()
        IgnisUITestSupport.assertHomeShellReady(app)

        let t = IgnisUITestSupport.interactionTimeout
        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeStatusHeading).waitForExistence(timeout: t),
            "STATUS heading"
        )
        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeNodeIdHeading).waitForExistence(timeout: t),
            "NODE ID heading"
        )
        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.snapshotSectionTitle).waitForExistence(timeout: t),
            "LIVE SNAPSHOT title"
        )
        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.networkFooterSignetBadge).waitForExistence(timeout: t),
            "Network footer (Signet badge)"
        )

        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeScroll).waitForExistence(timeout: t),
            "Home scroll container (ignis.home.scroll)"
        )

        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeCopyNodeId).waitForExistence(timeout: t),
            "Copy node id control"
        )
        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeShowNodeIdQR).waitForExistence(timeout: t),
            "Show node id QR control"
        )
    }

    func testHomeShowsBrandingAndStatusSection() {
        let app = IgnisUITestSupport.applicationUnderTest()
        app.launch()
        IgnisUITestSupport.assertHomeShellReady(app)

        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeStatusHeading)
                .waitForExistence(timeout: IgnisUITestSupport.interactionTimeout)
        )
    }

    func testLogConsoleSheetOpensAndDismisses() {
        let app = IgnisUITestSupport.applicationUnderTest()
        app.launch()
        IgnisUITestSupport.assertHomeShellReady(app)

        let logButton = app.buttons[IgnisUITestAccessibilityID.homeLogConsole]
        XCTAssertTrue(logButton.waitForExistence(timeout: IgnisUITestSupport.interactionTimeout))
        logButton.tap()

        let logsNavigationStack = IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.logsNavigationStack)
        XCTAssertTrue(logsNavigationStack.waitForExistence(timeout: IgnisUITestSupport.interactionTimeout))

        let done = app.buttons[IgnisUITestAccessibilityID.logsDone]
        XCTAssertTrue(done.waitForExistence(timeout: IgnisUITestSupport.interactionTimeout), "Log sheet should expose Done.")

        XCTAssertTrue(
            IgnisUITestSupport.logConsoleBodyAppeared(in: app, timeout: IgnisUITestSupport.interactionTimeout),
            "Log console should show the empty placeholder or the log list."
        )
        done.tap()

        XCTAssertTrue(homeBrandTitle(in: app).waitForExistence(timeout: IgnisUITestSupport.interactionTimeout))
    }

    func testHomeScrollViewExists() {
        let app = IgnisUITestSupport.applicationUnderTest()
        app.launch()
        IgnisUITestSupport.assertHomeShellReady(app)

        XCTAssertTrue(
            IgnisUITestSupport.element(app, id: IgnisUITestAccessibilityID.homeScroll)
                .waitForExistence(timeout: IgnisUITestSupport.interactionTimeout),
            "Home scroll should be findable by accessibility identifier."
        )
    }

    func testSnapshotQuickActionsAppearWhenNodeRunning() throws {
        let app = IgnisUITestSupport.applicationUnderTest()
        app.launch()
        IgnisUITestSupport.assertHomeShellReady(app)

        let connect = app.buttons[IgnisUITestAccessibilityID.snapshotConnectPeer]
        guard connect.waitForExistence(timeout: IgnisUITestSupport.snapshotRunningTimeout) else {
            throw XCTSkip("Snapshot toolbar did not appear (node may not have reached running).")
        }

        let scanInviteQR = app.buttons[IgnisUITestAccessibilityID.snapshotScanInviteQR]
        let showInviteQR = app.buttons[IgnisUITestAccessibilityID.snapshotShowInviteQR]
        let t = IgnisUITestSupport.interactionTimeout
        XCTAssertTrue(scanInviteQR.waitForExistence(timeout: t))
        XCTAssertTrue(showInviteQR.waitForExistence(timeout: t))
        XCTAssertTrue(connect.isHittable)
        XCTAssertTrue(scanInviteQR.isHittable)
        XCTAssertTrue(showInviteQR.isHittable)
    }
}
