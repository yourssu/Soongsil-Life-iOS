import SwiftUI

struct SoomsilCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.white000)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.gray100, lineWidth: 1)
            }
    }
}

extension View {
    func soomsilCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(SoomsilCardModifier(cornerRadius: cornerRadius))
    }
}
