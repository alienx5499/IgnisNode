//
//  PeersListSheet.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Lists peers from `bootstrap.peers`; toolbar for invite QR and per-row navigation to `PeerDetailSheet`.
//

import SwiftUI

struct PeersListSheet: View {
    @Bindable var bootstrap: NodeBootstrap
    let theme: GlassTheme

    @Environment(\.dismiss) private var dismiss

    @State private var showInviteQR = false
    @State private var showPeersTabScanner = false
    @State private var peersListScanError: String?
    @State private var selectedPeer: IgnisPeerInfo?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(localized: "Pairing"))
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(theme.sectionLabel)
                        connectStep(
                            1,
                            String(
                                localized: "One device: tap Show invite QR (above) so the other person can scan your lightning: URI."
                            )
                        )
                        connectStep(
                            2,
                            String(
                                localized: "Other device: tap + or Scan on Live Snapshot / here, read their invite QR, and connect (same Wi‑Fi helps)."
                            )
                        )
                        connectStep(
                            3,
                            String(
                                localized: "When a row below shows Connected, pairing is complete."
                            )
                        )
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                    )

                    if bootstrap.peers.isEmpty {
                        Text(String(localized: "No peers listed yet. Follow the steps above, then check back here."))
                            .font(.system(size: 14))
                            .foregroundStyle(theme.sectionLabel)
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(bootstrap.peers) { peer in
                                Button {
                                    selectedPeer = peer
                                } label: {
                                    peerCard(peer)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.screenBase)
            .navigationTitle(String(localized: "Peers"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        peersListScanError = nil
                        showPeersTabScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(theme.btcGlyph)
                    }
                    .buttonStyle(.plain)
                    .disabled(!bootstrap.isRunning)
                    .accessibilityLabel(String(localized: "Scan invite QR"))

                    Button {
                        showInviteQR = true
                    } label: {
                        Image(systemName: "qrcode")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(theme.btcGlyph)
                    }
                    .buttonStyle(.plain)
                    .disabled(!bootstrap.isRunning)
                    .accessibilityLabel(String(localized: "Show invite QR"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                    .foregroundStyle(theme.statusText)
                }
            }
            .sheet(isPresented: $showInviteQR) {
                PeerInviteQRSheet(bootstrap: bootstrap, theme: theme)
            }
            .fullScreenCover(isPresented: $showPeersTabScanner) {
                PeerQRScannerView(
                    onScan: { raw in
                        showPeersTabScanner = false
                        Task { await handlePeersListScan(raw) }
                    },
                    onCancel: {
                        showPeersTabScanner = false
                    }
                )
                .ignoresSafeArea()
            }
            .alert(
                String(localized: "Could not connect"),
                isPresented: Binding(
                    get: { peersListScanError != nil },
                    set: { if !$0 { peersListScanError = nil } }
                )
            ) {
                Button(String(localized: "OK"), role: .cancel) {
                    peersListScanError = nil
                }
            } message: {
                Text(peersListScanError ?? "")
            }
            .sheet(item: $selectedPeer) { peer in
                PeerDetailSheet(bootstrap: bootstrap, peer: peer, theme: theme)
            }
        }
    }

    private func handlePeersListScan(_ raw: String) async {
        switch PeerConnectionParser.parse(raw) {
        case let .full(pk, addr):
            do {
                try await bootstrap.connectToPeer(pubkey: pk, address: addr)
            } catch {
                peersListScanError = error.localizedDescription
            }
        default:
            peersListScanError = String(
                localized: "That QR did not contain a full invite (node id and address together)."
            )
        }
    }

    private func connectStep(_ index: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.statusText)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(theme.statusText.opacity(0.14))
                )
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(theme.sectionLabel.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
    }

    private func peerCard(_ peer: IgnisPeerInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(peer.isConnected ? Color(hex: "30D158") : theme.sectionLabel.opacity(0.35))
                    .frame(width: 8, height: 8)
                Text(peer.isConnected ? String(localized: "Connected") : String(localized: "Disconnected"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.sectionLabel)
            }
            Text(peer.nodeId)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.nodeIdText)
                .textSelection(.enabled)
            Text(peer.address)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.sectionLabel.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(theme.isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
        )
    }
}
