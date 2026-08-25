import SwiftUI

private struct SoomsilDetailNavigationModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}

extension View {
    func soomsilDetailNavigation(title: String) -> some View {
        modifier(SoomsilDetailNavigationModifier(title: title))
    }
}
