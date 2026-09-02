import SwiftUI
import UIKit

extension Color {
    static let soomsilBlue600 = Color("blue_600")
    static let soomsilBlue500 = Color("blue_500")
    static let soomsilBlue200 = Color("blue_200")
    static let soomsilBlue100 = Color("blue_100")
    static let soomsilBlue50 = Color("blue_50")
    static let soomsilGray25 = Color("gray_25")
    static let soomsilGray100 = Color("gray_100")
    static let soomsilGray200 = Color("gray_200")
    static let soomsilGray950 = Color("gray_950")
    static let soomsilGray500 = Color("gray_500")
    static let soomsilSlate400 = Color("slate_400")
    // Temporary aliases while feature-level semantic colors are being migrated.
    static let soomsilGreen50 = Color("pointColor050")
    static let soomsilGreen500 = Color("logoIndigo")
    static let soomsilRed50 = Color("warningRed050")
    static let soomsilRed500 = Color("warningRed500")

    static let soomsilBackground = adaptive(
        light: assetColor("white000"),
        dark: assetColor("gray_950")
    )
    static let soomsilSurface = adaptive(
        light: assetColor("white000"),
        dark: assetColor("gray_900")
    )
    static let soomsilMutedSurface = adaptive(
        light: assetColor("gray_25"),
        dark: assetColor("gray_800").withAlphaComponent(0.36)
    )
    static let soomsilInputSurface = adaptive(
        light: assetColor("white000"),
        dark: assetColor("gray_800").withAlphaComponent(0.52)
    )
    static let soomsilBorder = adaptive(
        light: assetColor("slate_100"),
        dark: assetColor("gray_800").withAlphaComponent(0.45)
    )
    static let soomsilPrimaryText = adaptive(
        light: assetColor("gray_950"),
        dark: assetColor("white000")
    )
    static let soomsilSecondaryText = adaptive(
        light: assetColor("gray_500"),
        dark: assetColor("gray_500")
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func assetColor(_ name: String) -> UIColor {
        UIColor(named: name) ?? .clear
    }
}

struct SoomsilCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.soomsilSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.soomsilBorder, lineWidth: 1)
            }
    }
}

extension View {
    func soomsilCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(SoomsilCardModifier(cornerRadius: cornerRadius))
    }
}
