//
//  IgnisNodeApp.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//

import SwiftUI

@main
struct IgnisNodeApp: App {
    @State private var bootstrap = IgnisNodeBootstrap()

    var body: some Scene {
        WindowGroup {
            ContentView(bootstrap: bootstrap)
        }
    }
}
