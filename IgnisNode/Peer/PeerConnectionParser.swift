//
//  PeerConnectionParser.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Parses QR / paste payloads into pubkey, address, or both (before `PeerAddressNormalization`).
//

import Foundation

enum PeerConnectionParseResult {
    case full(pubkey: String, address: String)
    case pubkeyOnly(String)
    case addressOnly(String)
}

enum PeerConnectionParser {
    static func parse(_ raw: String) -> PeerConnectionParseResult {
        let s = PeerAddressNormalization.stripLightningURIPrefix(raw)
        if let at = s.firstIndex(of: "@") {
            let left = String(s[..<at]).trimmingCharacters(in: .whitespaces)
            let right = String(s[s.index(after: at)...]).trimmingCharacters(in: .whitespaces)
            if !left.isEmpty, !right.isEmpty {
                return .full(pubkey: left, address: right)
            }
        }
        var pubkeyCandidate = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if pubkeyCandidate.hasPrefix("0x") || pubkeyCandidate.hasPrefix("0X") {
            pubkeyCandidate = String(pubkeyCandidate.dropFirst(2))
        }
        let hexDigits = pubkeyCandidate.filter(\.isHexDigit)
        let isHexOnly = pubkeyCandidate.count == hexDigits.count && !hexDigits.isEmpty
        if isHexOnly, hexDigits.count == 66 {
            return .pubkeyOnly(pubkeyCandidate)
        }
        return .addressOnly(s)
    }
}
