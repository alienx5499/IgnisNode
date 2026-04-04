//
//  SnapshotFormatting.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Pure formatters and predicates for the live snapshot card (no SwiftUI).
//

import Foundation

/// Pure formatters and small predicates shared by the snapshot UI (no view code).
enum SnapshotFormatting {
    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    /// Drives the “new wallet” explainer: live node with zero balances and no channels, expected before funding, not a failed read.
    static func snapshotLooksLikeFreshWallet(live: Bool, snapshot: IgnisNodeSnapshot) -> Bool {
        guard live else { return false }
        return snapshot.spendableOnchainSats == 0
            && snapshot.lightningSats == 0
            && snapshot.channelCount == 0
    }

    static func formatBlockHeight(_ height: UInt32?) -> String {
        guard let height else { return "-" }
        return decimalFormatter.string(from: NSNumber(value: height)) ?? "\(height)"
    }

    static func formatSats(_ sats: UInt64?) -> String {
        guard let sats else { return "-" }
        let num = decimalFormatter.string(from: NSNumber(value: sats)) ?? "\(sats)"
        return String(format: String(localized: "%@ sats"), locale: .current, num)
    }

    static func formatSyncAge(from past: Date?, now: Date = .now) -> String {
        guard let past else { return "-" }
        let interval = now.timeIntervalSince(past)
        guard interval >= 0 else { return "-" }
        if interval < 1 {
            return String(localized: "now")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: past, relativeTo: now)
    }

    static var appVersionLine: String? {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        guard let short else { return nil }
        if let build, build != short {
            return String(
                format: String(localized: "IgnisNode %@ (%@)"),
                locale: .current,
                short,
                build
            )
        }
        return String(format: String(localized: "IgnisNode %@"), locale: .current, short)
    }
}
