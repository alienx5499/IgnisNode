//
//  ReceiveSignetSection.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Signet receive address row: copy, new address, show QR (parent gates visibility on `Running`).
//

import Observation
import SwiftUI

struct ReceiveSignetSection: View {
    @Bindable var bootstrap: NodeBootstrap
    let theme: GlassTheme
    @Binding var showReceiveAddressQR: Bool

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                if bootstrap.receiveAddress.isEmpty {
                    Text(String(localized: "Could not load a receive address. Check the node, then try again."))
                        .font(.system(size: theme.nodeIdFontSize))
                        .foregroundStyle(theme.sectionLabel)
                        .padding(13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(in: .rect(cornerRadius: 14.0))

                    Button(String(localized: "Retry")) {
                        bootstrap.refreshReceiveAddress()
                    }
                    .font(.system(size: theme.copyFontSize, weight: .semibold))
                    .buttonStyle(.glass)
                } else {
                    Text(bootstrap.receiveAddress)
                        .font(.system(size: theme.nodeIdFontSize, weight: .regular, design: .monospaced))
                        .foregroundStyle(theme.nodeIdText)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .padding(13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(in: .rect(cornerRadius: 14.0))

                    HStack(spacing: 8) {
                        CopyFeedbackGlassButton(
                            idleTitle: String(localized: "Copy address"),
                            copiedTitle: String(localized: "Copied"),
                            value: bootstrap.receiveAddress,
                            accessibilityAnnouncement: String(localized: "Address copied to clipboard"),
                            theme: theme
                        )
                        Button(String(localized: "New address")) {
                            bootstrap.refreshReceiveAddress()
                        }
                        .font(.system(size: theme.copyFontSize, weight: .semibold))
                        .foregroundStyle(theme.copyLabel)
                        .buttonStyle(.glass)

                        Button {
                            showReceiveAddressQR = true
                        } label: {
                            Label(String(localized: "Show QR"), systemImage: "qrcode")
                                .font(.system(size: theme.copyFontSize))
                                .foregroundStyle(theme.copyLabel)
                        }
                        .buttonStyle(.glass)
                    }
                }

                Text(String(localized: "Send Signet from a faucet to this address. Your on-chain balance updates after confirmations."))
                    .font(.system(size: 9))
                    .foregroundStyle(theme.sectionLabel.opacity(0.85))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
