//
//  PeerDetailSheet.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Per-peer detail: connection state, optional channel capacity, disconnect.
//

import SwiftUI

struct PeerDetailSheet: View {
    @Bindable var bootstrap: NodeBootstrap
    let peer: IgnisPeerInfo
    let theme: GlassTheme

    @Environment(\.dismiss) private var dismiss

    @State private var isDisconnecting = false
    @State private var errorMessage: String?

    private var stats: (channelCount: Int, outboundMsat: UInt64, inboundMsat: UInt64) {
        bootstrap.peerChannelStats(counterpartyNodeId: peer.nodeId)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusRow

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "Node ID"))
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(theme.sectionLabel)
                        Text(peer.nodeId)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(theme.nodeIdText)
                            .textSelection(.enabled)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "P2P address"))
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(theme.sectionLabel)
                        Text(peer.address)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.sectionLabel.opacity(0.95))
                            .textSelection(.enabled)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Lightning with this peer"))
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(theme.sectionLabel)
                        metricLine(
                            String(localized: "Channels"),
                            "\(stats.channelCount)"
                        )
                        metricLine(
                            String(localized: "Outbound capacity"),
                            AmountFormatting.formatLightningCapacityMsat(stats.outboundMsat)
                        )
                        metricLine(
                            String(localized: "Inbound capacity"),
                            AmountFormatting.formatLightningCapacityMsat(stats.inboundMsat)
                        )
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.errorText)
                    }

                    Button {
                        Task { await disconnect() }
                    } label: {
                        HStack {
                            if isDisconnecting {
                                ProgressView()
                                    .tint(theme.errorText)
                            }
                            Text(String(localized: "Disconnect peer"))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.glass)
                    .disabled(isDisconnecting)
                    .foregroundStyle(theme.errorText)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.screenBase)
            .navigationTitle(String(localized: "Peer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                    .foregroundStyle(theme.statusText)
                }
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(peer.isConnected ? Color(hex: "30D158") : theme.sectionLabel.opacity(0.35))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(peer.isConnected ? String(localized: "Connected") : String(localized: "Disconnected"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.statusText)
                Text(
                    peer.isPersisted
                        ? String(localized: "Saved peer (reconnects when possible)")
                        : String(localized: "Session only")
                )
                .font(.system(size: 12))
                .foregroundStyle(theme.sectionLabel)
            }
        }
    }

    private func metricLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(theme.sectionLabel)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.statusText.opacity(0.95))
        }
    }

    private func disconnect() async {
        errorMessage = nil
        isDisconnecting = true
        defer { isDisconnecting = false }
        do {
            try bootstrap.disconnectPeer(nodeId: peer.nodeId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
