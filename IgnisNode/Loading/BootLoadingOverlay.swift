//
//  BootLoadingOverlay.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Full-screen dimmed scrim and centered Lottie while the node starts or awaits first wallet sync.
//

import SwiftUI

struct BootLoadingOverlay: View {
    let theme: GlassTheme

    var body: some View {
        GeometryReader { geo in
            let inset = geo.safeAreaInsets
            let bottomBar = max(inset.bottom, 20) + 12
            let topReserve = inset.top + 56
            let lottieSize = min(
                geo.size.width * 0.88,
                max(120, geo.size.height - topReserve - bottomBar) * 0.72,
                400
            )

            ZStack {
                ZStack {
                    Color.black.opacity(theme.isDark ? 0.52 : 0.36)
                        .ignoresSafeArea()
                    theme.screenBase.opacity(theme.isDark ? 0.42 : 0.32)
                        .ignoresSafeArea()
                }

                LoaderLottieView()
                    .frame(width: lottieSize, height: lottieSize)
                    .clipped()
                    .layoutPriority(-1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Boot loading · dark") {
    BootLoadingOverlay(theme: GlassTheme(colorScheme: .dark))
        .ignisPreviewBackground(.dark)
}

#Preview("Boot loading · light") {
    BootLoadingOverlay(theme: GlassTheme(colorScheme: .light))
        .ignisPreviewBackground(.light)
}

private extension View {
    func ignisPreviewBackground(_ scheme: ColorScheme) -> some View {
        environment(\.colorScheme, scheme)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(scheme == .dark ? Color.black : Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255))
    }
}
