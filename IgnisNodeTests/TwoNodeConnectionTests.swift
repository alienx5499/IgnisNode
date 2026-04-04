//
//  TwoNodeConnectionTests.swift
//  IgnisNodeTests
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Integration-style test: two ephemeral Signet `Node`s on loopback connect as Lightning peers.
//

import Darwin
import LDKNode
import XCTest

private enum TestEphemeralPort {
    /// Binds `127.0.0.1:0` and returns the assigned port (socket closed before return).
    ///
    /// Another process could theoretically claim the port before LDK binds; `makeStartedNodeWithRetries`
    /// retries with a fresh port when `Node.start()` fails.
    static func loopbackTCP() throws -> Int {
        let fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        guard fd >= 0 else {
            throw NSError(domain: "TwoNodeConnectionTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "socket() failed"])
        }
        defer { close(fd) }
        var reuse: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout.size(ofValue: reuse)))
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout.size(ofValue: addr))
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(0).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        let bindResult = withUnsafePointer(to: &addr) {
            bind(fd, UnsafeRawPointer($0).assumingMemoryBound(to: sockaddr.self), socklen_t(MemoryLayout<sockaddr_in>.size))
        }
        guard bindResult == 0 else {
            throw NSError(domain: "TwoNodeConnectionTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "bind failed"])
        }
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        var out = sockaddr_in()
        let gsn = withUnsafeMutablePointer(to: &out) {
            getsockname(fd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &len)
        }
        guard gsn == 0 else {
            throw NSError(domain: "TwoNodeConnectionTests", code: 3, userInfo: [NSLocalizedDescriptionKey: "getsockname failed"])
        }
        return Int(UInt16(bigEndian: out.sin_port))
    }
}

final class TwoNodeConnectionTests: XCTestCase {
    func testTwoSignetNodesConnectOverLoopback() async throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("IgnisNode-2node-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }

        let dirA = base.appendingPathComponent("a")
        let dirB = base.appendingPathComponent("b")
        try FileManager.default.createDirectory(at: dirA, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dirB, withIntermediateDirectories: true)

        let (nodeA, portA) = try Self.makeStartedNodeWithRetries(storage: dirA)
        defer { try? nodeA.stop() }
        let (nodeB, portB) = try Self.makeStartedNodeWithRetries(storage: dirB, excludingListenPort: portA)
        defer { try? nodeB.stop() }

        XCTAssertNotEqual(portA, portB, "Ephemeral listen ports should differ")

        let idA = nodeA.nodeId()

        try nodeB.connect(nodeId: idA, address: "127.0.0.1:\(portA)", persist: false)

        let deadline = Date().addingTimeInterval(30)
        var connected = false
        var lastPeerDump = "(none)"
        while Date() < deadline {
            let peers = nodeB.listPeers()
            lastPeerDump = peers.map { "id=\($0.nodeId.prefix(12))… connected=\($0.isConnected)" }.joined(separator: " | ")
            if peers.contains(where: { $0.nodeId == idA && $0.isConnected }) {
                connected = true
                break
            }
            try await Task.sleep(nanoseconds: 250_000_000)
        }

        XCTAssertTrue(
            connected,
            "Node B should list node A as connected. Looking for idA prefix \(idA.prefix(12))… Last listPeers: \(lastPeerDump)"
        )
    }

    /// Retries with new ephemeral ports if `start()` fails (e.g. address already in use after port reuse race).
    private static func makeStartedNodeWithRetries(
        storage: URL,
        excludingListenPort: Int? = nil,
        maxAttempts: Int = 12
    ) throws -> (Node, Int) {
        var lastError: Error?
        for _ in 0 ..< maxAttempts {
            var port = try TestEphemeralPort.loopbackTCP()
            if let exclude = excludingListenPort {
                var guardCount = 0
                while port == exclude, guardCount < 8 {
                    port = try TestEphemeralPort.loopbackTCP()
                    guardCount += 1
                }
                if port == exclude { continue }
            }
            do {
                let node = try makeStartedNode(storage: storage, listenPort: port)
                return (node, port)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? NSError(
            domain: "TwoNodeConnectionTests",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "makeStartedNodeWithRetries exhausted attempts"]
        )
    }

    private static func makeStartedNode(storage: URL, listenPort: Int) throws -> Node {
        var config = defaultConfig()
        config.storageDirPath = storage.path
        config.network = .signet
        config.listeningAddresses = ["127.0.0.1:\(listenPort)"]

        let builder = Builder.fromConfig(config: config)
        let syncConfig = EsploraSyncConfig(
            backgroundSyncConfig: BackgroundSyncConfig(
                onchainWalletSyncIntervalSecs: 120,
                lightningWalletSyncIntervalSecs: 60,
                feeRateCacheUpdateIntervalSecs: 1200
            )
        )
        builder.setChainSourceEsplora(serverUrl: "https://blockstream.info/signet/api", config: syncConfig)
        builder.setGossipSourceRgs(rgsServerUrl: "https://rgs.mutinynet.com/snapshot")

        let words = generateEntropyMnemonic(wordCount: nil)
        builder.setEntropyBip39Mnemonic(mnemonic: words, passphrase: nil)

        let node = try builder.build()
        try node.start()
        return node
    }
}
