//
//  QRCodeView.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Sheet with a Core Image generated QR for an arbitrary string (node id, address, etc.).
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct QRCodeView: View {
    let title: String
    let value: String
    let theme: GlassTheme

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(theme.sectionLabel)

                if value.isEmpty {
                    Text(String(localized: "Nothing to encode yet."))
                        .font(.system(size: 14))
                        .foregroundStyle(theme.sectionLabel)
                        .padding(.vertical, 32)
                } else if let image = Self.qrCodeImage(from: value) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )

                    Text(value)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(theme.nodeIdText)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                        .padding(.horizontal, 8)
                } else {
                    Text(String(localized: "Could not build a QR code for this value."))
                        .font(.system(size: 14))
                        .foregroundStyle(theme.errorText)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.screenBase)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                    .foregroundStyle(theme.statusText)
                }
            }
        }
    }

    private static func qrCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale: CGFloat = 12
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
