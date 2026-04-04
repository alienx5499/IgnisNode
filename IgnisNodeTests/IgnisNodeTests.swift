//
//  IgnisNodeTests.swift
//  IgnisNodeTests
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Unit tests for app helpers (e.g. `NodeStorage` path layout).
//

@testable import IgnisNode
import XCTest

final class IgnisNodeTests: XCTestCase {
    func testDataDirectoryCreatesPerNetworkSubfolderUnderIgnisNode() throws {
        let url = try NodeStorage.dataDirectoryURL(networkSubfolder: "signet")
        XCTAssertTrue(url.hasDirectoryPath)
        XCTAssertEqual(url.lastPathComponent, "signet")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, NodeStorage.folderName)
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }
}
