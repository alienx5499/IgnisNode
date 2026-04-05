//
//  PeerSupport.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Shared validation for peer host fields and user-facing LDK `NodeError` text.
//

import Foundation
import LDKNode

enum PeerAddressInputValidation {
    /// True when the string looks like an on-chain address or BOLT11-ish payload, not a P2P host:port.
    static func looksLikeOnChainOrInvoiceNotHost(_ s: String) -> Bool {
        let t = s.lowercased()
        if t.hasPrefix("tb1") || t.hasPrefix("bc1") || t.hasPrefix("bcrt1") { return true }
        if t.hasPrefix("lnbc") || t.hasPrefix("lntb") || t.hasPrefix("lnbs") || t.hasPrefix("lightning:") { return true }
        return false
    }
}

enum PeerConnectErrorMessages {
    static func userMessage(for error: NodeError) -> String {
        let port = NodeP2P.listenPort
        switch error {
        case let .InvalidSocketAddress(message):
            return String(localized: "Need a network address like 192.168.1.5:\(port), not a tb1 receive address. Details: ") + message
        case let .InvalidNetwork(message):
            return String(localized: "That peer is not on Signet. This app only connects to Signet Lightning nodes. ") + message
        case let .InvalidPublicKey(message), let .InvalidNodeId(message):
            return String(localized: "Invalid public key (use 66-character hex). ") + message
        case let .ConnectionFailed(message):
            return String(localized: "Could not complete the connection (offline peer, firewall, or wrong address). ") + message
        default:
            return String(describing: error)
        }
    }
}
