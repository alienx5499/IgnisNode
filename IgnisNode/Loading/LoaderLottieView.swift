//
//  LoaderLottieView.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Wraps Lottie `BitcoinLoader` from bundle (dotLottie or JSON under `Resources/BitcoinLoader/`) with async load + placeholder.
//

import Lottie
import SwiftUI

struct LoaderLottieView: View {
    var body: some View {
        LottieView {
            if let dot = try? await loadDotLottie() {
                return .dotLottieFile(dot)
            }
            if let anim = loadJSONAnimation() {
                return .lottieAnimation(anim)
            }
            return nil
        } placeholder: {
            ProgressView()
        }
        .playing(loopMode: .loop)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }

    private func loadDotLottie() async throws -> DotLottieFile {
        if let dot = try? await DotLottieFile.named("BitcoinLoader", bundle: .main) {
            return dot
        }
        if let dot = try? await DotLottieFile.named("BitcoinLoader", bundle: .main, subdirectory: "Resources/BitcoinLoader") {
            return dot
        }
        if let url = Bundle.main.url(forResource: "BitcoinLoader", withExtension: "lottie")
            ?? Bundle.main.url(forResource: "BitcoinLoader", withExtension: "lottie", subdirectory: "Resources/BitcoinLoader")
        {
            return try await DotLottieFile.loadedFrom(url: url)
        }
        throw DotLottieError.noDataLoaded
    }

    private func loadJSONAnimation() -> LottieAnimation? {
        LottieAnimation.named("BitcoinLoader", bundle: .main)
            ?? LottieAnimation.named("BitcoinLoader", bundle: .main, subdirectory: "Resources/BitcoinLoader")
    }
}

#Preview {
    LoaderLottieView()
        .frame(width: 200, height: 200)
        .padding()
}
