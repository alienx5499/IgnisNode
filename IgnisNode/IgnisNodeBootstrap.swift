//
//  IgnisNodeBootstrap.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//

import Foundation
import LDKNode
import Observation

private enum IgnisNodeDefaults {
    static let network: Network = .signet
    static let esploraURL = "https://blockstream.info/signet/api"
    static let rgsURL = "https://rgs.mutinynet.com/snapshot/"
}

@MainActor
@Observable
final class IgnisNodeBootstrap {
    private var node: Node?

    private(set) var nodeId: String = ""
    private(set) var status: String = "Idle"
    private(set) var lastError: String?

    func start() async {
        lastError = nil
        status = "Preparing storage…"
        do {
            let dataURL = try IgnisNodeStorage.dataDirectoryURL(network: IgnisNodeDefaults.network)
            let storagePath = dataURL.path
            let seedPhrasePath = dataURL.appendingPathComponent("seed_phrase")
            let keySeedPath = dataURL.appendingPathComponent("keys_seed")

            status = "Configuring node…"
            var config = defaultConfig()
            config.storageDirPath = storagePath
            config.network = IgnisNodeDefaults.network

            let builder = Builder.fromConfig(config: config)

            let syncConfig = EsploraSyncConfig(
                backgroundSyncConfig: BackgroundSyncConfig(
                    onchainWalletSyncIntervalSecs: 120,
                    lightningWalletSyncIntervalSecs: 60,
                    feeRateCacheUpdateIntervalSecs: 1200
                )
            )
            builder.setChainSourceEsplora(serverUrl: IgnisNodeDefaults.esploraURL, config: syncConfig)
            builder.setGossipSourceRgs(rgsServerUrl: IgnisNodeDefaults.rgsURL)

            let words: String
            if let saved = try? String(contentsOfFile: seedPhrasePath.path, encoding: .utf8),
               !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                words = saved.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if !FileManager.default.fileExists(atPath: keySeedPath.path) {
                words = generateEntropyMnemonic(wordCount: nil)
                try words.write(toFile: seedPhrasePath.path, atomically: true, encoding: .utf8)
            } else {
                words = ""
            }
            if !words.isEmpty {
                builder.setEntropyBip39Mnemonic(mnemonic: words, passphrase: nil)
            }

            status = "Starting…"
            let built = try builder.build()
            try built.start()
            node = built
            nodeId = built.nodeId()
            status = "Running"
        } catch {
            lastError = error.localizedDescription
            status = "Failed"
        }
    }

    func stop() {
        try? node?.stop()
        node = nil
    }
}
