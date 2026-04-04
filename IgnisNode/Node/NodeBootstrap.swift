//
//  NodeBootstrap.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Owns the LDK `Node` lifecycle (Signet, Esplora, RGS), periodic snapshots, peers, and UI-facing state.
//  Peer strings are normalized before `connect` so manual entry, QR, and pastes match LDK’s expected form.
//

import Foundation
import LDKNode
import Observation

// MARK: - Defaults & UI models

private enum NodeDefaults {
    /// If sync timestamps never arrive (e.g. offline), still reveal the main UI after this.
    static let bootOverlayMaxWaitWithoutWalletSync: TimeInterval = 30
    static let network: Network = .signet
    /// No trailing `/`. Esplora paths like `/fee-estimates` are appended by the client.
    static let esploraURL = "https://blockstream.info/signet/api"
    /// No trailing `/`. LDK appends `/{timestamp}`; a trailing slash would yield `//…`.
    static let rgsURL = "https://rgs.mutinynet.com/snapshot"
    static let snapshotPollInterval: Duration = .seconds(2.5)
    /// Cached so the home receive address survives restarts until `newAddress()` moves the HD chain.
    static let receiveAddressCacheFilename = "ui_receive_address.txt"
}

struct IgnisPeerInfo: Identifiable, Equatable, Hashable {
    let id: String
    let nodeId: String
    let address: String
    let isConnected: Bool
    let isPersisted: Bool
}

struct IgnisNodeSnapshot: Equatable {
    var chainHeight: UInt32?
    var spendableOnchainSats: UInt64?
    var lightningSats: UInt64?
    var channelCount: Int
    var peerCount: Int
    var lastOnchainSync: Date?
    var lastLightningSync: Date?

    static let empty = IgnisNodeSnapshot(
        chainHeight: nil,
        spendableOnchainSats: nil,
        lightningSats: nil,
        channelCount: 0,
        peerCount: 0,
        lastOnchainSync: nil,
        lastLightningSync: nil
    )
}

struct IgnisLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let message: String
}

enum IgnisNodePhase: Equatable {
    case idle
    case preparingStorage
    case configuring
    case starting
    case running
    case failed

    var localizedLabel: String {
        switch self {
        case .idle:
            String(localized: "Idle")
        case .preparingStorage:
            String(localized: "Preparing storage…")
        case .configuring:
            String(localized: "Configuring node…")
        case .starting:
            String(localized: "Starting…")
        case .running:
            String(localized: "Running")
        case .failed:
            String(localized: "Failed")
        }
    }
}

// MARK: - Bootstrap

@MainActor
@Observable
final class NodeBootstrap {
    private var node: Node?
    private var snapshotRefreshTask: Task<Void, Never>?

    private(set) var nodeId: String = ""
    private(set) var phase: IgnisNodePhase = .idle
    /// Localized status line for the home screen (derived from `phase`).
    var status: String {
        phase.localizedLabel
    }

    /// True when the LDK node is up and ready for RPC-style calls.
    var isRunning: Bool {
        phase == .running
    }

    private(set) var lastError: String?
    private(set) var snapshot: IgnisNodeSnapshot = .empty
    private(set) var peers: [IgnisPeerInfo] = []
    private(set) var receiveAddress: String = ""
    private(set) var logs: [IgnisLogEntry] = []

    private(set) var bootOverlayTimeoutPassed = false
    private var bootOverlayTimeoutTask: Task<Void, Never>?

    private var logPollingTask: Task<Void, Never>?
    private var lastLogOffset: UInt64 = 0

    /// True while booting, then until first on-chain or Lightning sync timestamp (or boot overlay timeout).
    var showBitcoinBootOverlay: Bool {
        guard lastError == nil else { return false }
        if phase != .running { return true }
        let s = snapshot
        if s.lastOnchainSync != nil || s.lastLightningSync != nil { return false }
        if bootOverlayTimeoutPassed { return false }
        return true
    }

    func start() async {
        if phase == .running, node != nil {
            return
        }
        snapshotRefreshTask?.cancel()
        snapshotRefreshTask = nil
        cancelBootOverlayTimeout()
        lastError = nil
        phase = .preparingStorage
        do {
            let dataURL = try NodeStorage.dataDirectoryURL(network: NodeDefaults.network)
            let storagePath = dataURL.path

            phase = .configuring
            var config = defaultConfig()
            config.storageDirPath = storagePath
            config.network = NodeDefaults.network
            config.listeningAddresses = ["0.0.0.0:\(NodeP2P.listenPort)"]

            let builder = Builder.fromConfig(config: config)

            let syncConfig = EsploraSyncConfig(
                backgroundSyncConfig: BackgroundSyncConfig(
                    onchainWalletSyncIntervalSecs: 120,
                    lightningWalletSyncIntervalSecs: 60,
                    feeRateCacheUpdateIntervalSecs: 1200
                )
            )
            builder.setChainSourceEsplora(
                serverUrl: Self.normalizedHttpBaseURL(NodeDefaults.esploraURL),
                config: syncConfig
            )
            builder.setGossipSourceRgs(rgsServerUrl: Self.normalizedHttpBaseURL(NodeDefaults.rgsURL))

            let logPath = dataURL.appendingPathComponent("ldk_node.log").path
            #if DEBUG
                builder.setFilesystemLogger(logFilePath: logPath, maxLogLevel: .debug)
            #else
                builder.setFilesystemLogger(logFilePath: logPath, maxLogLevel: .info)
            #endif

            let words = try Self.resolveMnemonicPhrase(dataURL: dataURL, network: NodeDefaults.network)
            if !words.isEmpty {
                builder.setEntropyBip39Mnemonic(mnemonic: words, passphrase: nil)
            }

            phase = .starting
            let built = try builder.build()
            try built.start()
            node = built
            nodeId = built.nodeId()
            phase = .running
            refreshSnapshot()
            if snapshot.lastOnchainSync == nil, snapshot.lastLightningSync == nil {
                scheduleBootOverlayTimeoutIfNeeded()
            }
            loadReceiveAddressForUI(dataURL: dataURL)
            startSnapshotPolling()
            startLogPolling(logPath: logPath)
        } catch {
            lastError = error.localizedDescription
            phase = .failed
            cancelBootOverlayTimeout()
            snapshot = .empty
            peers = []
            receiveAddress = ""
        }
    }

    func stop() {
        snapshotRefreshTask?.cancel()
        snapshotRefreshTask = nil
        logPollingTask?.cancel()
        logPollingTask = nil
        cancelBootOverlayTimeout()
        try? node?.stop()
        node = nil
        nodeId = ""
        phase = .idle
        lastError = nil
        snapshot = .empty
        peers = []
        receiveAddress = ""
    }

    func refreshReceiveAddress() {
        guard let node, phase == .running else {
            receiveAddress = ""
            return
        }
        do {
            let addr = try node.onchainPayment().newAddress()
            receiveAddress = addr
            persistReceiveAddressCache(addr)
        } catch {
            receiveAddress = ""
        }
    }

    private func loadReceiveAddressForUI(dataURL: URL) {
        guard let node, phase == .running else {
            receiveAddress = ""
            return
        }
        let cacheURL = dataURL.appendingPathComponent(NodeDefaults.receiveAddressCacheFilename)
        if let saved = try? String(contentsOf: cacheURL, encoding: .utf8) {
            let trimmed = saved.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                receiveAddress = trimmed
                return
            }
        }
        do {
            let addr = try node.onchainPayment().newAddress()
            receiveAddress = addr
            persistReceiveAddressCache(addr, dataURL: dataURL)
        } catch {
            receiveAddress = ""
        }
    }

    private func persistReceiveAddressCache(_ addr: String, dataURL: URL? = nil) {
        let base: URL?
        if let dataURL {
            base = dataURL
        } else {
            base = try? NodeStorage.dataDirectoryURL(network: NodeDefaults.network)
        }
        guard let base else { return }
        let url = base.appendingPathComponent(NodeDefaults.receiveAddressCacheFilename)
        try? addr.write(to: url, atomically: true, encoding: .utf8)
    }

    func refreshFromPull() async {
        guard phase == .running, let node else { return }
        try? node.syncWallets()
        refreshSnapshot()
    }

    func connectToPeer(pubkey: String, address: String) async throws {
        guard let node, phase == .running else {
            throw IgnisPeerConnectError.nodeNotRunning
        }
        let (pkRaw, addrRaw) = PeerAddressNormalization.coalescePeerFields(pubkey: pubkey, address: address)
        let pk = PeerAddressNormalization.normalizePeerPubkey(pkRaw)
        var addr = PeerAddressNormalization.normalizePeerAddress(addrRaw)
        addr = PeerAddressNormalization.bracketIPv6IfNeeded(addr)
        addr = PeerAddressNormalization.appendPortToBracketedIPv6IfMissing(addr)

        guard !pk.isEmpty, !addr.isEmpty else {
            throw IgnisPeerConnectError.incompletePeerInfo
        }

        try node.connect(nodeId: pk, address: addr, persist: true)
        refreshSnapshot()
    }

    func disconnectPeer(nodeId: String) throws {
        guard let node, phase == .running else {
            throw IgnisPeerConnectError.nodeNotRunning
        }
        let pk = PeerAddressNormalization.normalizePeerPubkey(nodeId)
        guard !pk.isEmpty else {
            throw IgnisPeerConnectError.invalidDisconnectTarget
        }
        try node.disconnect(nodeId: pk)
        refreshSnapshot()
    }

    func peerChannelStats(counterpartyNodeId: String) -> (channelCount: Int, outboundMsat: UInt64, inboundMsat: UInt64) {
        guard let node, phase == .running else {
            return (0, 0, 0)
        }
        let pid = PeerAddressNormalization.normalizePeerPubkey(counterpartyNodeId).lowercased()
        let list = node.listChannels().filter {
            PeerAddressNormalization.normalizePeerPubkey($0.counterpartyNodeId).lowercased() == pid
        }
        let outbound = list.reduce(UInt64(0)) { $0 + $1.outboundCapacityMsat }
        let inbound = list.reduce(UInt64(0)) { $0 + $1.inboundCapacityMsat }
        return (list.count, outbound, inbound)
    }

    private static func normalizedHttpBaseURL(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.last == "/" {
            s.removeLast()
        }
        return s
    }

    /// Loads mnemonic from Keychain, migrates legacy plaintext `seed_phrase` once, or creates a new wallet when no LDK key material exists.
    private static func resolveMnemonicPhrase(dataURL: URL, network: Network) throws -> String {
        let seedPhrasePath = dataURL.appendingPathComponent("seed_phrase")
        let keySeedPath = dataURL.appendingPathComponent("keys_seed")

        if let fromKeychain = MnemonicKeychain.load(network: network) {
            return fromKeychain
        }

        if let saved = try? String(contentsOfFile: seedPhrasePath.path, encoding: .utf8) {
            let trimmed = saved.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                try MnemonicKeychain.save(trimmed, network: network)
                try? FileManager.default.removeItem(at: seedPhrasePath)
                return trimmed
            }
        }

        if !FileManager.default.fileExists(atPath: keySeedPath.path) {
            let words = generateEntropyMnemonic(wordCount: nil)
            try MnemonicKeychain.save(words, network: network)
            return words
        }

        return ""
    }

    private func startSnapshotPolling() {
        snapshotRefreshTask?.cancel()
        snapshotRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: NodeDefaults.snapshotPollInterval)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.refreshSnapshot()
                }
            }
        }
    }

    private func refreshSnapshot() {
        guard let node else {
            snapshot = .empty
            peers = []
            return
        }
        let st = node.status()
        let balances = node.listBalances()
        let peerRows = node.listPeers().map { p in
            IgnisPeerInfo(
                id: p.nodeId,
                nodeId: p.nodeId,
                address: p.address,
                isConnected: p.isConnected,
                isPersisted: p.isPersisted
            )
        }
        peers = peerRows
        snapshot = IgnisNodeSnapshot(
            chainHeight: st.currentBestBlock.height,
            spendableOnchainSats: balances.spendableOnchainBalanceSats,
            lightningSats: balances.totalLightningBalanceSats,
            channelCount: node.listChannels().count,
            peerCount: peerRows.count,
            lastOnchainSync: Self.dateFromLDKTimestamp(st.latestOnchainWalletSyncTimestamp),
            lastLightningSync: Self.dateFromLDKTimestamp(st.latestLightningWalletSyncTimestamp)
        )
        if snapshot.lastOnchainSync != nil || snapshot.lastLightningSync != nil {
            bootOverlayTimeoutTask?.cancel()
            bootOverlayTimeoutTask = nil
        }
    }

    private func scheduleBootOverlayTimeoutIfNeeded() {
        bootOverlayTimeoutTask?.cancel()
        bootOverlayTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(NodeDefaults.bootOverlayMaxWaitWithoutWalletSync))
            guard !Task.isCancelled else { return }
            bootOverlayTimeoutPassed = true
        }
    }

    private func cancelBootOverlayTimeout() {
        bootOverlayTimeoutTask?.cancel()
        bootOverlayTimeoutTask = nil
        bootOverlayTimeoutPassed = false
    }

    private func startLogPolling(logPath: String) {
        logPollingTask?.cancel()
        let path = logPath
        logPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                guard let bootstrap = self else { return }
                let lastOffset = await MainActor.run { bootstrap.lastLogOffset }
                let (entries, newOffset) = Self.readNewLogChunk(path: path, lastOffset: lastOffset)
                await MainActor.run { [weak self] in
                    guard let bootstrap = self else { return }
                    bootstrap.lastLogOffset = newOffset
                    guard !entries.isEmpty else { return }
                    bootstrap.logs.append(contentsOf: entries)
                    if bootstrap.logs.count > 200 {
                        bootstrap.logs.removeFirst(bootstrap.logs.count - 200)
                    }
                }
            }
        }
    }

    private nonisolated static func readNewLogChunk(path: String, lastOffset: UInt64) -> (entries: [IgnisLogEntry], newOffset: UInt64) {
        guard let file = FileHandle(forReadingAtPath: path) else { return ([], lastOffset) }
        defer { try? file.close() }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            var offset = lastOffset
            if fileSize < offset {
                offset = 0
            }
            try file.seek(toOffset: offset)
            let data = file.readDataToEndOfFile()
            let newOffset = fileSize
            guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
                return ([], newOffset)
            }
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let entries = lines.map { IgnisLogEntry(timestamp: Date(), message: $0) }
            return (entries, newOffset)
        } catch {
            return ([], lastOffset)
        }
    }

    private static func dateFromLDKTimestamp(_ raw: UInt64?) -> Date? {
        guard let raw else { return nil }
        if raw > 10_000_000_000 {
            return Date(timeIntervalSince1970: TimeInterval(raw) / 1000)
        }
        return Date(timeIntervalSince1970: TimeInterval(raw))
    }
}

enum IgnisPeerConnectError: LocalizedError {
    case incompletePeerInfo
    case nodeNotRunning
    case invalidDisconnectTarget

    var errorDescription: String? {
        switch self {
        case .incompletePeerInfo:
            return String(localized: "Enter the node public key and the address (host:port), or paste pubkey@host:port in the public key field.")
        case .nodeNotRunning:
            return String(localized: "The node is not running. Wait until status is Running, then try again.")
        case .invalidDisconnectTarget:
            return String(localized: "Could not disconnect: invalid peer identifier.")
        }
    }
}
