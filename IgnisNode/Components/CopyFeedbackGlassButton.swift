//
//  CopyFeedbackGlassButton.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Reusable “Copy” -> “Copied” control with haptics and brief green confirmation.
//

import SwiftUI
import UIKit

struct CopyFeedbackGlassButton: View {
    let idleTitle: String
    let copiedTitle: String
    let value: String
    let accessibilityAnnouncement: String
    let theme: GlassTheme

    @State private var confirmed = false
    @State private var feedbackID = 0
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        Button {
            UIPasteboard.general.string = value
            feedbackID += 1
            UIAccessibility.post(notification: .announcement, argument: accessibilityAnnouncement)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                confirmed = true
            }
            resetTask?.cancel()
            resetTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1750))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    confirmed = false
                }
            }
        } label: {
            Text(confirmed ? copiedTitle : idleTitle)
                .font(.system(size: theme.copyFontSize))
                .foregroundStyle(confirmed ? Color(hex: "30D158") : theme.copyLabel)
                .contentTransition(.interpolate)
        }
        .sensoryFeedback(.success, trigger: feedbackID)
        .buttonStyle(.glass)
    }
}
