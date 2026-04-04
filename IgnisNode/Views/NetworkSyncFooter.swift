//
//  NetworkSyncFooter.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Bottom safe-area chips: Signet network, Esplora chain source, RGS gossip (read-only labels).
//

import SwiftUI

struct NetworkSyncFooter: View {
    let theme: GlassTheme

    private enum BadgeStyle {
        case signet
        case neutral
    }

    var body: some View {
        let signetTitle = String(localized: "Signet")
        let esploraTitle = String(localized: "Esplora")
        let rgsTitle = String(localized: "RGS")
        let combinedAccessibilityLabel = String(
            format: String(localized: "Network %@, chain %@, gossip %@"),
            locale: .current,
            signetTitle,
            esploraTitle,
            rgsTitle
        )
        return VStack(alignment: .trailing, spacing: 6) {
            Text(String(localized: "Network & sync"))
                .font(.system(size: 8, weight: .medium))
                .tracking(1)
                .foregroundStyle(theme.sectionLabel)
            GlassEffectContainer(spacing: 5) {
                HStack(spacing: 5) {
                    networkBadge(title: signetTitle, style: .signet)
                    networkBadge(title: esploraTitle, style: .neutral)
                    networkBadge(title: rgsTitle, style: .neutral)
                }
                .allowsHitTesting(false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(combinedAccessibilityLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func networkBadge(title: String, style: BadgeStyle) -> some View {
        switch style {
        case .signet:
            Text(title)
                .font(.system(size: theme.badgeFontSize, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .foregroundStyle(theme.signetBadgeText)
                .glassEffect(in: .capsule)
        case .neutral:
            Text(title)
                .font(.system(size: theme.badgeFontSize, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .foregroundStyle(theme.neutralBadgeText)
                .glassEffect(in: .capsule)
        }
    }
}
