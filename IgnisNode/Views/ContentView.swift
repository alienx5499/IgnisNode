//
//  ContentView.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Main home screen: themed chrome, node id, Signet receive, live snapshot, sheets, and boot overlay.
//  Calls `bootstrap.start()` on first appear and `bootstrap.stop()` when the scene enters background.
//

import Observation
import SwiftUI

struct ContentView: View {
    @Bindable var bootstrap: NodeBootstrap
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var showLogConsole = false
    @State private var showConnectPeer = false
    @State private var showPeerInviteQR = false
    @State private var showSnapshotPeerScanner = false
    @State private var snapshotPeerScanError: String?
    @State private var showPeersList = false
    @State private var showNodeIdQR = false
    @State private var showReceiveAddressQR = false

    private var theme: GlassTheme {
        GlassTheme(colorScheme: colorScheme)
    }

    private var showBitcoinLoader: Bool {
        bootstrap.showBitcoinBootOverlay
    }

    var body: some View {
        ZStack {
            theme.screenBase.ignoresSafeArea()

            AmbientBackground(theme: theme)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 10) {
                        Text(String(localized: "IGNIS NODE"))
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(theme.appName)
                        Spacer(minLength: 8)
                        Button {
                            showLogConsole = true
                        } label: {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(theme.appName)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel(String(localized: "Node log console"))
                        Text("₿")
                            .font(.system(size: 18))
                            .foregroundStyle(theme.btcGlyph)
                            .frame(minWidth: 22, alignment: .trailing)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, 36)

                    Text(String(localized: "STATUS"))
                        .font(.system(size: 9, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(theme.sectionLabel)
                        .padding(.bottom, 5)

                    HStack(spacing: 7) {
                        StatusPulseDot(theme: theme, phase: bootstrap.phase)
                        Text(bootstrap.status)
                            .font(theme.statusFont)
                            .foregroundStyle(theme.statusText)
                    }

                    if let err = bootstrap.lastError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(theme.errorText)
                            .padding(.top, 10)
                    }

                    Rectangle()
                        .fill(theme.divider)
                        .frame(height: 0.5)
                        .padding(.vertical, 20)

                    Text(String(localized: "NODE ID"))
                        .font(.system(size: 9, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(theme.sectionLabel)
                        .padding(.bottom, 5)

                    GlassEffectContainer(spacing: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(bootstrap.nodeId)
                                .font(.system(size: theme.nodeIdFontSize, weight: .regular, design: .monospaced))
                                .foregroundStyle(theme.nodeIdText)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(2)
                                .padding(13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassEffect(in: .rect(cornerRadius: 14.0))

                            HStack(spacing: 12) {
                                CopyFeedbackGlassButton(
                                    idleTitle: String(localized: "Copy to clipboard"),
                                    copiedTitle: String(localized: "Copied"),
                                    value: bootstrap.nodeId,
                                    accessibilityAnnouncement: String(localized: "Copied to clipboard"),
                                    theme: theme
                                )
                                Button {
                                    showNodeIdQR = true
                                } label: {
                                    Label(String(localized: "Show QR"), systemImage: "qrcode")
                                        .font(.system(size: theme.copyFontSize))
                                        .foregroundStyle(theme.copyLabel)
                                }
                                .buttonStyle(.glass)
                            }
                        }
                    }

                    if bootstrap.isRunning {
                        Text(String(localized: "RECEIVE (SIGNET)"))
                            .font(.system(size: 9, weight: .medium))
                            .tracking(3)
                            .foregroundStyle(theme.sectionLabel)
                            .padding(.top, 20)
                            .padding(.bottom, 5)

                        ReceiveSignetSection(
                            bootstrap: bootstrap,
                            theme: theme,
                            showReceiveAddressQR: $showReceiveAddressQR
                        )
                    }

                    NodeSnapshotPanel(
                        bootstrap: bootstrap,
                        theme: theme,
                        showSnapshotPeerScanner: $showSnapshotPeerScanner,
                        showPeerInviteQR: $showPeerInviteQR,
                        showConnectPeer: $showConnectPeer,
                        showPeersList: $showPeersList
                    )
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .refreshable {
                await bootstrap.refreshFromPull()
            }
            .sheet(isPresented: $showLogConsole) {
                LogConsoleView(logs: bootstrap.logs, theme: theme)
            }
            .sheet(isPresented: $showConnectPeer) {
                ConnectPeerModal(
                    bootstrap: bootstrap,
                    theme: theme,
                    onConnected: {
                        showPeersList = true
                    }
                )
            }
            .sheet(isPresented: $showPeerInviteQR) {
                PeerInviteQRSheet(
                    bootstrap: bootstrap,
                    theme: theme,
                    onIncomingPeer: {
                        showPeersList = true
                    }
                )
            }
            .sheet(isPresented: $showPeersList) {
                PeersListSheet(bootstrap: bootstrap, theme: theme)
            }
            .sheet(isPresented: $showNodeIdQR) {
                QRCodeView(title: String(localized: "NODE ID"), value: bootstrap.nodeId, theme: theme)
            }
            .sheet(isPresented: $showReceiveAddressQR) {
                QRCodeView(title: String(localized: "SIGNET ADDRESS"), value: bootstrap.receiveAddress, theme: theme)
            }
            .fullScreenCover(isPresented: $showSnapshotPeerScanner) {
                PeerQRScannerView(
                    onScan: { raw in
                        showSnapshotPeerScanner = false
                        Task { await handleSnapshotPeerScan(raw) }
                    },
                    onCancel: {
                        showSnapshotPeerScanner = false
                    }
                )
                .ignoresSafeArea()
            }
            .alert(
                String(localized: "Could not connect"),
                isPresented: Binding(
                    get: { snapshotPeerScanError != nil },
                    set: { if !$0 { snapshotPeerScanError = nil } }
                )
            ) {
                Button(String(localized: "OK"), role: .cancel) {
                    snapshotPeerScanError = nil
                }
            } message: {
                Text(snapshotPeerScanError ?? "")
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                NetworkSyncFooter(theme: theme)
            }

            if showBitcoinLoader {
                BootLoadingOverlay(theme: theme)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showBitcoinLoader)
        .task {
            await bootstrap.start()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                bootstrap.stop()
            } else if newPhase == .active, oldPhase == .background {
                Task { await bootstrap.start() }
            }
        }
    }

    private func handleSnapshotPeerScan(_ raw: String) async {
        switch PeerConnectionParser.parse(raw) {
        case let .full(pk, addr):
            do {
                try await bootstrap.connectToPeer(pubkey: pk, address: addr)
                showPeersList = true
            } catch {
                snapshotPeerScanError = error.localizedDescription
            }
        default:
            snapshotPeerScanError = String(
                localized: "That QR did not contain a full invite (node id and address together). Tap + and scan the host’s invite QR."
            )
        }
    }
}

#Preview("Dark") {
    ContentView(bootstrap: NodeBootstrap())
        .environment(\.colorScheme, .dark)
}

#Preview("Light") {
    ContentView(bootstrap: NodeBootstrap())
        .environment(\.colorScheme, .light)
}
