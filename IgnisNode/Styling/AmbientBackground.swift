//
//  AmbientBackground.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Non-interactive radial glows behind the main scroll content (same palette as `GlassTheme`).
//

import SwiftUI

struct AmbientBackground: View {
    let theme: GlassTheme

    var body: some View {
        GeometryReader { geo in
            let p1 = theme.glowPrimaryPosition
            let p2 = theme.glowSecondaryPosition
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.glowPrimary,
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .position(x: geo.size.width * p1.x, y: geo.size.height * p1.y)
                    .blur(radius: theme.glowPrimaryBlur)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.glowSecondary,
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .position(x: geo.size.width * p2.x, y: geo.size.height * p2.y)
                    .blur(radius: theme.glowSecondaryBlur)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
