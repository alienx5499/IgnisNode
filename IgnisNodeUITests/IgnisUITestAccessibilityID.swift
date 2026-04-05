//
//  IgnisUITestAccessibilityID.swift
//  IgnisNodeUITests
//
//  Created by PRABAL PATRA on 05/04/26.
//

import Foundation
import XCTest

enum IgnisUITestAccessibilityID {
    static let homeScroll = "ignis.home.scroll"
    static let homeBrandTitle = "ignis.home.brandTitle"
    static let homeStatusHeading = "ignis.home.statusHeading"
    static let homeNodeIdHeading = "ignis.home.nodeIdHeading"
    static let homeLogConsole = "ignis.home.logConsole"
    static let homeCopyNodeId = "ignis.home.copyNodeId"
    static let homeShowNodeIdQR = "ignis.home.showNodeIdQR"

    static let networkFooterSignetBadge = "ignis.networkFooter.signetBadge"

    static let snapshotSectionTitle = "ignis.snapshot.sectionTitle"
    static let snapshotScanInviteQR = "ignis.snapshot.scanInviteQR"
    static let snapshotShowInviteQR = "ignis.snapshot.showInviteQR"
    static let snapshotConnectPeer = "ignis.snapshot.connectPeer"

    static let logsDone = "ignis.logs.done"
    static let logsNavigationStack = "ignis.logs.navigationStack"
    static let logsEmptyState = "ignis.logs.emptyState"
    static let logsListScroll = "ignis.logs.listScroll"
}

enum IgnisUITestSupport {
    static let uiTestingLaunchArgument = "-ui-testing"
    static let homeShellTimeout: TimeInterval = 30
    static let interactionTimeout: TimeInterval = 15
    static let snapshotRunningTimeout: TimeInterval = 90

    static func applicationUnderTest() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(uiTestingLaunchArgument)
        return app
    }

    static func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// `Text` with an accessibility identifier is usually `XCUIElementType.staticText`; prefer this for labels.
    static func staticText(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.staticTexts[id]
    }

    static func assertHomeShellReady(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let title = element(app, id: IgnisUITestAccessibilityID.homeBrandTitle)
        XCTAssertTrue(
            title.waitForExistence(timeout: homeShellTimeout),
            "Home did not appear within \(homeShellTimeout)s (launch with \(uiTestingLaunchArgument)).",
            file: file,
            line: line
        )
    }

    static func waitForAnyToExist(_ elements: [XCUIElement], timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for el in elements where el.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return elements.contains { $0.exists }
    }

    static func logConsoleBodyAppeared(in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let idEmpty = IgnisUITestAccessibilityID.logsEmptyState
        let idList = IgnisUITestAccessibilityID.logsListScroll
        let candidates: [XCUIElement] = [
            app.staticTexts.matching(identifier: idEmpty).firstMatch,
            app.scrollViews.matching(identifier: idList).firstMatch,
            app.otherElements.matching(identifier: idEmpty).firstMatch,
            app.otherElements.matching(identifier: idList).firstMatch,
            element(app, id: idEmpty),
            element(app, id: idList),
        ]
        return waitForAnyToExist(candidates, timeout: timeout)
    }
}
