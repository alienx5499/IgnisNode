//
//  NodeStorage.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Resolves `Application Support/IgnisNode/<network>/` and ensures the directory exists before LDK uses it.
//

import Foundation
import LDKNode

enum NodeStorage {
    static let folderName = "IgnisNode"

    static func dataDirectoryURL(network: Network) throws -> URL {
        try dataDirectoryURL(networkSubfolder: networkFolderName(network))
    }

    static func dataDirectoryURL(networkSubfolder: String) throws -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw Error.applicationSupportUnavailable
        }
        let url = appSupport
            .appendingPathComponent(folderName, isDirectory: true)
            .appendingPathComponent(networkSubfolder, isDirectory: true)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return url
    }

    private static func networkFolderName(_ network: Network) -> String {
        switch network {
        case .bitcoin: return "bitcoin"
        case .testnet: return "testnet"
        case .signet: return "signet"
        case .regtest: return "regtest"
        }
    }

    enum Error: Swift.Error {
        case applicationSupportUnavailable
    }
}
