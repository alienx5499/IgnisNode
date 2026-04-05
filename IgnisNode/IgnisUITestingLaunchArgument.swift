//
//  IgnisUITestingLaunchArgument.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 05/04/26.
//
//  Shared contract: UI tests append this; production code checks `ProcessInfo` (see `NodeBootstrap`).
//

import Foundation

enum IgnisUITestingLaunchArgument {
    /// Passed by UI tests so the app can skip overlays and deterministic waits.
    static let value = "-ui-testing"
}
