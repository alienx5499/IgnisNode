//
//  LogConsoleView.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Scrollable tail of `IgnisLogEntry` lines (populated from the on-disk LDK log via `NodeBootstrap`).
//

import SwiftUI

struct LogConsoleView: View {
    let logs: [IgnisLogEntry]
    let theme: GlassTheme

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if logs.isEmpty {
                    Text(String(localized: "No log lines yet. They appear as the node writes to its log file."))
                        .font(.system(size: 13))
                        .foregroundStyle(theme.sectionLabel)
                        .multilineTextAlignment(.center)
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement()
                        .accessibilityIdentifier("ignis.logs.emptyState")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(logs) { entry in
                                Text(entry.message)
                                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                                    .foregroundStyle(theme.nodeIdText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(16)
                    }
                    .accessibilityElement()
                    .accessibilityIdentifier("ignis.logs.listScroll")
                }
            }
            .background(theme.screenBase)
            .navigationTitle(String(localized: "Logs"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                    .foregroundStyle(theme.statusText)
                    .accessibilityIdentifier("ignis.logs.done")
                }
            }
        }
        .accessibilityIdentifier("ignis.logs.navigationStack")
    }
}
