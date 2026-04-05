//
//  IgnisNodeApp.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  App entry: one shared `NodeBootstrap` for the lifetime of the process.
//

import SwiftUI

@main
struct IgnisNodeApp: App {
    @State private var bootstrap = NodeBootstrap()

    var body: some Scene {
        WindowGroup {
            ContentView(bootstrap: bootstrap)
        }
    }
}
