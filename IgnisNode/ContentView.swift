//
//  ContentView.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//

import SwiftUI

struct ContentView: View {
    @Bindable var bootstrap: IgnisNodeBootstrap
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(bootstrap.status)
                .font(.headline)
            if let err = bootstrap.lastError {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            if !bootstrap.nodeId.isEmpty {
                Text("Node id")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(bootstrap.nodeId)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await bootstrap.start()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                bootstrap.stop()
            }
        }
    }
}

#Preview {
    ContentView(bootstrap: IgnisNodeBootstrap())
}
