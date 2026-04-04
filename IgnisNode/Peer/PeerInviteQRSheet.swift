//
//  PeerInviteQRSheet.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Shows a `lightning:` invite QR for this node’s LAN address so another device can connect inbound.
//

import SwiftUI

struct PeerInviteQRSheet: View {
    @Bindable var bootstrap: NodeBootstrap
    let theme: GlassTheme
    var onIncomingPeer: (() -> Void)? = nil

    private enum Phase {
        case loading
        case ready(String)
        case noLanIP
        case nodeNotReady
    }

    @State private var phase: Phase = .loading
    @State private var baselinePeerCount = 0
    @State private var didDismissForIncoming = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ZStack {
                    theme.screenBase.ignoresSafeArea()
                    ProgressView()
                        .tint(theme.statusText)
                }
                .task {
                    await resolvePhase()
                }
            case .nodeNotReady:
                errorChrome(
                    message: String(localized: "Start the node, then try again.")
                )
            case .noLanIP:
                errorChrome(
                    message: String(localized: "Could not read a Wi‑Fi IP. Join the same Wi‑Fi and try again.")
                )
            case let .ready(uri):
                QRCodeView(
                    title: String(localized: "SCAN TO CONNECT"),
                    value: uri,
                    theme: theme
                )
            }
        }
        .onAppear {
            baselinePeerCount = bootstrap.peers.count
            didDismissForIncoming = false
        }
        .onChange(of: bootstrap.peers.count) { _, newCount in
            guard case .ready = phase else { return }
            guard !didDismissForIncoming, newCount > baselinePeerCount else { return }
            didDismissForIncoming = true
            dismiss()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(280))
                onIncomingPeer?()
            }
        }
    }

    private func errorChrome(message: String) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(theme.sectionLabel)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.screenBase)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismissEmbedded()
                    }
                    .foregroundStyle(theme.statusText)
                }
            }
        }
    }

    private func dismissEmbedded() {
        dismiss()
    }

    private func resolvePhase() async {
        guard bootstrap.isRunning, !bootstrap.nodeId.isEmpty else {
            phase = .nodeNotReady
            return
        }
        guard let ip = LocalWiFiIPv4.primary() else {
            phase = .noLanIP
            return
        }
        let uri = "lightning:\(bootstrap.nodeId)@\(ip):\(NodeP2P.listenPort)"
        phase = .ready(uri)
    }
}
