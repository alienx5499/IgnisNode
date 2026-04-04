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
            let storagePath = try IgnisNodeStorage.dataDirectoryURL(network: IgnisNodeDefaults.network).path

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

            let mnemonic = generateEntropyMnemonic(wordCount: nil)
            builder.setEntropyBip39Mnemonic(mnemonic: mnemonic, passphrase: nil)

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
