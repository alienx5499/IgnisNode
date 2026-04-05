//
//  GlassTheme.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Semantic palette for the glass UI: backgrounds, section labels, badges, and status styling by `ColorScheme`.
//

import SwiftUI

struct GlassTheme {
    let isDark: Bool

    init(colorScheme: ColorScheme) {
        isDark = colorScheme == .dark
    }

    var screenBase: Color {
        isDark ? Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255) : Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    }

    var glowPrimary: Color {
        isDark ? Color(hex: "FFD600").opacity(0.08) : Color(hex: "FFD600").opacity(0.12)
    }

    var glowSecondary: Color {
        isDark ? Color.white.opacity(0.05) : Color(red: 0, green: 122 / 255, blue: 1).opacity(0.06)
    }

    var glowPrimaryPosition: (x: CGFloat, y: CGFloat) {
        isDark ? (0.20, 0.20) : (0.25, 0.15)
    }

    var glowSecondaryPosition: (x: CGFloat, y: CGFloat) {
        isDark ? (0.80, 0.70) : (0.75, 0.65)
    }

    var glowPrimaryBlur: CGFloat {
        isDark ? 42 : 38
    }

    var glowSecondaryBlur: CGFloat {
        isDark ? 48 : 44
    }

    var appName: Color {
        isDark ? Color.white.opacity(0.30) : Color.black.opacity(0.30)
    }

    var btcGlyph: Color {
        isDark ? Color(hex: "FFD600").opacity(0.60) : Color(red: 180 / 255, green: 140 / 255, blue: 0).opacity(0.70)
    }

    var sectionLabel: Color {
        isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.35)
    }

    var statusText: Color {
        isDark ? .white : .black
    }

    var statusFont: Font {
        .system(size: 24, weight: .ultraLight)
    }

    var divider: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    var nodeIdFontSize: CGFloat {
        9
    }

    var nodeIdText: Color {
        isDark ? Color.white.opacity(0.75) : Color.black.opacity(0.65)
    }

    var copyFontSize: CGFloat {
        10
    }

    var copyLabel: Color {
        isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    var badgeFontSize: CGFloat {
        8
    }

    var signetBadgeText: Color {
        isDark ? Color(hex: "FFD600") : Color(red: 120 / 255, green: 85 / 255, blue: 0)
    }

    var neutralBadgeText: Color {
        isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    var errorText: Color {
        Color(hex: "FF453A")
    }
}
