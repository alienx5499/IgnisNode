//
//  ConnectPeerModal.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Sheet to enter peer pubkey + host:port; toolbar opens QR scan for partial or full invite payloads.
//

import LDKNode
import SwiftUI

struct ConnectPeerModal: View {
    @Bindable var bootstrap: NodeBootstrap
    let theme: GlassTheme
    var onConnected: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var pubkey = ""
    @State private var address = ""
    @State private var showQRScanner = false
    @State private var errorMessage: String?
    @State private var isConnecting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "Enter the other device’s node id and P2P host:port, or paste pubkey@host:port. Tap the toolbar icon to scan a QR (full invite connects automatically; partial scans fill the fields below). Signet only. No tb1 or invoice strings."))
                    .font(.system(size: 13))
                    .foregroundStyle(theme.sectionLabel)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Public key"))
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(theme.sectionLabel)
                    peerField {
                        TextField("", text: $pubkey, prompt: Text(String(localized: "hex pubkey")).foregroundStyle(theme.sectionLabel.opacity(0.5)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(theme.nodeIdText)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Peer host (IP:port)"))
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(theme.sectionLabel)
                    peerField {
                        TextField("", text: $address, prompt: Text(verbatim: "192.168.x.x:\(NodeP2P.listenPort)").foregroundStyle(theme.sectionLabel.opacity(0.5)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(theme.nodeIdText)
                    }
                }

                if isConnecting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(theme.statusText)
                        Text(String(localized: "Connecting…"))
                            .font(.system(size: 13))
                            .foregroundStyle(theme.sectionLabel)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.errorText)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await connectManual() }
                } label: {
                    Text(String(localized: "Connect"))
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                .disabled(isConnecting || !bootstrap.isRunning || trimmed(pubkey).isEmpty || trimmed(address).isEmpty)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(theme.screenBase)
            .navigationTitle(String(localized: "Connect peer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(theme.copyLabel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        errorMessage = nil
                        showQRScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(theme.btcGlyph)
                    }
                    .buttonStyle(.plain)
                    .disabled(!bootstrap.isRunning || isConnecting)
                    .accessibilityLabel(String(localized: "Scan peer invite QR"))
                }
            }
            .fullScreenCover(isPresented: $showQRScanner) {
                PeerQRScannerView(
                    onScan: { raw in
                        applyScannedPayload(raw)
                        showQRScanner = false
                        if case .full = PeerConnectionParser.parse(raw) {
                            Task { await connectFromFullScan(raw) }
                        }
                    },
                    onCancel: {
                        showQRScanner = false
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    private func peerField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
            )
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func applyScannedPayload(_ raw: String) {
        errorMessage = nil
        switch PeerConnectionParser.parse(raw) {
        case let .full(pk, addr):
            pubkey = pk
            address = addr
        case let .pubkeyOnly(pk):
            pubkey = pk
        case let .addressOnly(addr):
            address = addr
        }
    }

    private func connectFromFullScan(_ raw: String) async {
        switch PeerConnectionParser.parse(raw) {
        case let .full(_, addr):
            let addrIn = addr.trimmingCharacters(in: .whitespacesAndNewlines)
            if PeerAddressInputValidation.looksLikeOnChainOrInvoiceNotHost(addrIn) {
                errorMessage = String(localized: "That QR is not a valid peer address. Use the invite QR from the other device’s Peers screen.")
                return
            }
            await connectUsingFields()
        default:
            break
        }
    }

    private func connectManual() async {
        errorMessage = nil
        let addrIn = trimmed(address)
        if PeerAddressInputValidation.looksLikeOnChainOrInvoiceNotHost(addrIn) {
            let port = NodeP2P.listenPort
            errorMessage = String(localized: "This field is not for your tb1/bc1 receive address or invoices. Enter the other device’s LAN IP and port (e.g. 192.168.1.8:\(port)) from its Wi‑Fi settings.")
            return
        }
        await connectUsingFields()
    }

    private func connectUsingFields() async {
        let addrIn = trimmed(address)
        if PeerAddressInputValidation.looksLikeOnChainOrInvoiceNotHost(addrIn) {
            return
        }
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await bootstrap.connectToPeer(pubkey: trimmed(pubkey), address: addrIn)
            dismiss()
            onConnected?()
        } catch let nodeError as NodeError {
            errorMessage = PeerConnectErrorMessages.userMessage(for: nodeError)
        } catch let ignis as IgnisPeerConnectError {
            errorMessage = ignis.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
