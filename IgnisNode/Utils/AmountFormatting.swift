//
//  AmountFormatting.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Human-readable Lightning / on-chain amounts for labels (no SwiftUI).
//

import Foundation

enum AmountFormatting {
    private static let btcCapacityFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 8
        f.maximumFractionDigits = 8
        return f
    }()

    private static let satsCapacityFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    /// Formats millisatoshi capacity as sats, or BTC for very large values (peer/channel summaries).
    static func formatLightningCapacityMsat(_ msat: UInt64) -> String {
        let sats = msat / 1000
        if sats >= 100_000_000 {
            let satsDecimal = Decimal(sats)
            let btc = satsDecimal / Decimal(100_000_000)
            let num = NSDecimalNumber(decimal: btc)
            let formatted = btcCapacityFormatter.string(from: num) ?? "\(btc)"
            return String(format: String(localized: "%@ BTC"), locale: .current, formatted)
        }
        let num = satsCapacityFormatter.string(from: NSNumber(value: sats)) ?? "\(sats)"
        return String(format: String(localized: "%@ sats"), locale: .current, num)
    }
}
