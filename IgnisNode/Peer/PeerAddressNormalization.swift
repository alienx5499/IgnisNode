//
//  PeerAddressNormalization.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Pure string transforms so manual entry and QR payloads match what LDK `Node.connect` expects.
//

import Foundation

enum PeerAddressNormalization {
    /// Strips a leading `lightning:` URI prefix (case-insensitive) after trimming whitespace.
    static func stripLightningURIPrefix(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.lowercased().hasPrefix("lightning:") {
            t = String(t.dropFirst("lightning:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
    }

    /// Merge `pubkey@host` pastes, strip URI noise, bracket IPv6, default port (`NodeP2P.listenPort`).
    static func coalescePeerFields(pubkey: String, address: String) -> (String, String) {
        var pk = pubkey.trimmingCharacters(in: .whitespacesAndNewlines)
        var addr = address.trimmingCharacters(in: .whitespacesAndNewlines)

        if pk.contains("@") {
            let parts = pk.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                pk = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                addr = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if addr.contains("@"), pk.isEmpty {
            let parts = addr.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                pk = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                addr = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return (pk, addr)
    }

    static func normalizePeerPubkey(_ s: String) -> String {
        var t = stripLightningURIPrefix(s)
        if t.hasPrefix("0x") || t.hasPrefix("0X") { t.removeFirst(2) }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizePeerAddress(_ s: String) -> String {
        var t = stripLightningURIPrefix(s)
        let lower = t.lowercased()
        for prefix in ["https://", "http://", "tcp://"] {
            if lower.hasPrefix(prefix) {
                t = String(t.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        if let slash = t.firstIndex(of: "/") {
            t = String(t[..<slash])
        }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)

        // Unbracketed IPv6 with trailing `:port` → `[addr]:port` before default-port / wrap logic.
        if !t.isEmpty, !t.hasPrefix("["), t.filter({ $0 == ":" }).count >= 2 {
            let rewritten = bracketIPv6IfNeeded(t)
            if rewritten != t {
                t = rewritten
            }
        }

        let port = NodeP2P.listenPort
        if !t.isEmpty, !t.contains(":") {
            t = "\(t):\(port)"
        }
        guard !t.isEmpty else { return t }
        if !t.hasPrefix("["), !hasLikelyExplicitPortSuffix(t) {
            let colonCount = t.filter { $0 == ":" }.count
            if t.contains("::") || colonCount >= 2 {
                return "[\(t)]:\(port)"
            }
        }
        return t
    }

    /// True when there is an explicit TCP port: `[any]:port`, or `host:port` with exactly one colon (IPv4 / hostname).
    /// Unbracketed IPv6 must use `…:port` only after `bracketIPv6IfNeeded` has normalized to `[…]:port`.
    private static func hasLikelyExplicitPortSuffix(_ t: String) -> Bool {
        let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.hasPrefix("[") {
            guard let close = trimmed.firstIndex(of: "]") else { return false }
            let afterBracket = trimmed.index(after: close)
            guard afterBracket < trimmed.endIndex, trimmed[afterBracket] == ":" else { return false }
            let portStr = String(trimmed[trimmed.index(after: afterBracket)...])
            guard !portStr.isEmpty,
                  portStr.allSatisfy(\.isNumber),
                  let p = Int(portStr),
                  (1 ... 65535).contains(p) else { return false }
            return true
        }
        guard trimmed.filter({ $0 == ":" }).count == 1,
              let lastColon = trimmed.lastIndex(of: ":") else { return false }
        let after = String(trimmed[trimmed.index(after: lastColon)...])
        guard !after.isEmpty,
              after.allSatisfy(\.isNumber),
              let p = Int(after),
              (1 ... 65535).contains(p) else { return false }
        return true
    }

    /// If host is unbracketed IPv6 with a numeric port suffix, rewrite to `[host]:port` so the address parser is unambiguous.
    static func bracketIPv6IfNeeded(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastColon = t.lastIndex(of: ":") else { return t }
        let after = t[t.index(after: lastColon)...]
        let portStr = String(after)
        guard !portStr.isEmpty, portStr.allSatisfy(\.isNumber), (1 ... 5).contains(portStr.count) else {
            return t
        }
        let hostPart = String(t[..<lastColon])
        guard hostPart.contains(":"), !hostPart.hasPrefix("[") else { return t }
        // `2001:db8::` + `1234` is a last hextet, not `:1234` port — do not rewrite.
        if hostPart.hasSuffix("::") {
            return t
        }
        return "[\(hostPart)]:\(portStr)"
    }

    static func appendPortToBracketedIPv6IfMissing(_ s: String) -> String {
        let port = NodeP2P.listenPort
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.hasPrefix("["), let close = t.firstIndex(of: "]") else { return t }
        let after = t.index(after: close)
        if after == t.endIndex {
            return t + ":\(port)"
        }
        let suffix = t[after...]
        if suffix == ":" {
            return String(t[..<after]) + ":\(port)"
        }
        return t
    }
}
