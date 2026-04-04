//
//  StatusPulseDot.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Status dot beside the label: green pulse only while running; static colors for other phases.
//

import SwiftUI

struct StatusPulseDot: View {
    let theme: GlassTheme
    let phase: IgnisNodePhase

    @State private var pulse = false

    private var dotColor: Color {
        switch phase {
        case .running:
            Color(hex: "30D158")
        case .failed:
            Color(hex: "FF453A")
        case .preparingStorage, .configuring, .starting:
            Color(hex: "FF9F0A")
        case .idle:
            theme.isDark ? Color.white.opacity(0.38) : Color.black.opacity(0.35)
        }
    }

    private var shouldPulse: Bool {
        phase == .running
    }

    var body: some View {
        Group {
            if shouldPulse {
                ZStack {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                        .opacity(0.45)
                        .shadow(color: dotColor.opacity(theme.isDark ? 0.6 : 0.35), radius: 3)
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulse ? 1.5 : 1.0)
                        .opacity(pulse ? 0 : 1)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(dotColor.opacity(0.4))
                        .frame(width: 7, height: 7)
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                }
            }
        }
        .frame(width: 14, height: 14)
        .onAppear {
            syncPulseAnimation()
        }
        .onChange(of: phase) { _, _ in
            pulse = false
            syncPulseAnimation()
        }
    }

    private func syncPulseAnimation() {
        guard shouldPulse else { return }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}
