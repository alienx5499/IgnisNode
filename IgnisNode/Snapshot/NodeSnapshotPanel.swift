//
//  NodeSnapshotPanel.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Live snapshot card: chain height, balances, channel/peer counts, sync ages, and peer quick actions.
//

import Observation
import SwiftUI

struct NodeSnapshotPanel: View {
    @Bindable var bootstrap: NodeBootstrap
    let theme: GlassTheme
    @Binding var showSnapshotPeerScanner: Bool
    @Binding var showPeerInviteQR: Bool
    @Binding var showConnectPeer: Bool
    @Binding var showPeersList: Bool

    var body: some View {
        let live = bootstrap.isRunning
        let s = bootstrap.snapshot

        return GlassEffectContainer(spacing: 10) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text(String(localized: "LIVE SNAPSHOT"))
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(theme.sectionLabel)
                        .accessibilityIdentifier("ignis.snapshot.sectionTitle")
                    Spacer(minLength: 8)
                    if live {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: "30D158"))
                                .frame(width: 6, height: 6)
                            Text(String(localized: "Live"))
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color(hex: "30D158").opacity(0.95))
                        }
                        .accessibilityLabel(String(localized: "Node is running, metrics updating"))
                    } else {
                        Text("-")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.sectionLabel.opacity(0.6))
                            .accessibilityLabel(String(localized: "Snapshot unavailable until the node is running"))
                    }

                    if live {
                        HStack(spacing: 6) {
                            Button {
                                showSnapshotPeerScanner = true
                            } label: {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(theme.appName)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel(String(localized: "Scan peer invite QR to connect"))
                            .accessibilityIdentifier("ignis.snapshot.scanInviteQR")

                            Button {
                                showPeerInviteQR = true
                            } label: {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(theme.appName)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel(String(localized: "Show invite QR for others to scan"))
                            .accessibilityIdentifier("ignis.snapshot.showInviteQR")

                            Button {
                                showConnectPeer = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(theme.appName)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel(String(localized: "Connect to a peer manually"))
                            .accessibilityIdentifier("ignis.snapshot.connectPeer")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    snapshotChainHero(live: live, heightText: SnapshotFormatting.formatBlockHeight(s.chainHeight))

                    Rectangle()
                        .fill(theme.divider)
                        .frame(height: 0.5)
                        .padding(.vertical, 12)

                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            snapshotMetricTile(
                                icon: "bitcoinsign.circle",
                                title: String(localized: "On-chain"),
                                value: live ? SnapshotFormatting.formatSats(s.spendableOnchainSats) : "-",
                                live: live
                            )
                            snapshotMetricTile(
                                icon: "bolt.fill",
                                title: String(localized: "Lightning"),
                                value: live ? SnapshotFormatting.formatSats(s.lightningSats) : "-",
                                live: live
                            )
                        }
                        GridRow {
                            snapshotMetricTile(
                                icon: "link",
                                title: String(localized: "Channels"),
                                value: live ? "\(s.channelCount)" : "-",
                                live: live
                            )
                            snapshotMetricTile(
                                icon: "antenna.radiowaves.left.and.right",
                                title: String(localized: "Peers"),
                                value: live ? "\(s.peerCount)" : "-",
                                live: live,
                                action: live
                                    ? {
                                        showPeersList = true
                                    }
                                    : nil
                            )
                        }
                    }

                    Rectangle()
                        .fill(theme.divider)
                        .frame(height: 0.5)
                        .padding(.vertical, 12)

                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        VStack(alignment: .leading, spacing: 8) {
                            snapshotSyncRow(
                                title: String(localized: "On-chain sync"),
                                value: live ? SnapshotFormatting.formatSyncAge(from: s.lastOnchainSync, now: context.date) : "-",
                                live: live
                            )
                            snapshotSyncRow(
                                title: String(localized: "Lightning sync"),
                                value: live ? SnapshotFormatting.formatSyncAge(from: s.lastLightningSync, now: context.date) : "-",
                                live: live
                            )
                        }
                    }

                    if SnapshotFormatting.snapshotLooksLikeFreshWallet(live: live, snapshot: s) {
                        Text(
                            String(
                                localized: "0 balances and no channels are normal for a new wallet. Send Signet to your on-chain address, then open a channel. Lightning and peers update after you connect and fund activity."
                            )
                        )
                        .font(.system(size: 9))
                        .foregroundStyle(theme.sectionLabel.opacity(0.8))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(in: .rect(cornerRadius: 14.0))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(snapshotAccessibilitySummary(live: live, snapshot: s))

                if let line = SnapshotFormatting.appVersionLine {
                    Text(line)
                        .font(.system(size: 9, weight: .medium))
                        .tracking(0.3)
                        .foregroundStyle(theme.sectionLabel.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func snapshotChainHero(live: Bool, heightText: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.down.forward.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.btcGlyph.opacity(0.85))
                Text(String(localized: "Chain height"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.sectionLabel)
            }
            Text(heightText)
                .font(.system(size: 26, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(live ? theme.statusText : theme.sectionLabel.opacity(0.55))
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: heightText)
        }
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func snapshotMetricTile(
        icon: String,
        title: String,
        value: String,
        live: Bool,
        action: (() -> Void)? = nil
    ) -> some View {
        let showDisclosure = action != nil && live
        if let action {
            Button(action: action) {
                snapshotMetricTileContent(
                    icon: icon,
                    title: title,
                    value: value,
                    live: live,
                    showDisclosure: showDisclosure
                )
            }
            .buttonStyle(.plain)
            .disabled(!live)
            .accessibilityLabel("\(title), \(value)")
        } else {
            snapshotMetricTileContent(
                icon: icon,
                title: title,
                value: value,
                live: live,
                showDisclosure: false
            )
        }
    }

    private func snapshotMetricTileContent(
        icon: String,
        title: String,
        value: String,
        live: Bool,
        showDisclosure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.sectionLabel.opacity(0.75))
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(theme.sectionLabel)
                if showDisclosure {
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(theme.sectionLabel.opacity(0.45))
                }
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(live ? theme.statusText.opacity(0.95) : theme.sectionLabel.opacity(0.5))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(theme.isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
        )
    }

    private func snapshotSyncRow(title: String, value: String, live: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 10))
                .foregroundStyle(theme.sectionLabel.opacity(0.55))
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.sectionLabel.opacity(0.85))
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(live ? theme.statusText.opacity(0.88) : theme.sectionLabel.opacity(0.45))
        }
    }

    private func snapshotAccessibilitySummary(live: Bool, snapshot: IgnisNodeSnapshot) -> String {
        guard live else {
            return String(localized: "Node snapshot unavailable until running")
        }
        let height = SnapshotFormatting.formatBlockHeight(snapshot.chainHeight)
        let onChain = SnapshotFormatting.formatSats(snapshot.spendableOnchainSats)
        let ln = SnapshotFormatting.formatSats(snapshot.lightningSats)
        let ch = "\(snapshot.channelCount)"
        let pe = "\(snapshot.peerCount)"
        let o = SnapshotFormatting.formatSyncAge(from: snapshot.lastOnchainSync, now: Date())
        let l = SnapshotFormatting.formatSyncAge(from: snapshot.lastLightningSync, now: Date())
        return String(
            format: String(localized: "Chain height %@, on-chain %@, Lightning %@, %@ channels, %@ peers. Last on-chain sync %@, last Lightning sync %@."),
            locale: .current,
            height,
            onChain,
            ln,
            ch,
            pe,
            o,
            l
        )
    }
}
