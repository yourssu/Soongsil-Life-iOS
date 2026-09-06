import SwiftUI
import UIKit

private struct SoomsilDetailNavigationModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.editor)
            .tint(.black000)
            .toolbar(.visible, for: .navigationBar)
    }
}

extension View {
    func soomsilDetailNavigation(title: String) -> some View {
        modifier(SoomsilDetailNavigationModifier(title: title))
    }

    func soomsilInteractivePopGesture() -> some View {
        background {
            SoomsilInteractivePopGestureEnabler()
                .frame(width: 0, height: 0)
        }
    }
}

private struct SoomsilInteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InteractivePopGestureViewController {
        InteractivePopGestureViewController()
    }

    func updateUIViewController(
        _ uiViewController: InteractivePopGestureViewController,
        context: Context
    ) {
        uiViewController.enableInteractivePopGesture()
    }

    static func dismantleUIViewController(
        _ uiViewController: InteractivePopGestureViewController,
        coordinator: ()
    ) {
        uiViewController.restoreInteractivePopGestureDelegate()
    }
}

private final class InteractivePopGestureViewController: UIViewController {
    private let popGestureDelegate = SoomsilInteractivePopGestureDelegate()
    private weak var installedGestureRecognizer: UIGestureRecognizer?
    private weak var originalGestureDelegate: UIGestureRecognizerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableInteractivePopGesture()
    }

    func enableInteractivePopGesture() {
        DispatchQueue.main.async { [weak self] in
            guard
                let self,
                let navigationController = self.navigationController,
                let gestureRecognizer = navigationController.interactivePopGestureRecognizer
            else {
                return
            }

            if gestureRecognizer.delegate !== self.popGestureDelegate {
                self.originalGestureDelegate = gestureRecognizer.delegate
            }

            self.popGestureDelegate.navigationController = navigationController
            self.installedGestureRecognizer = gestureRecognizer
            gestureRecognizer.delegate = self.popGestureDelegate
            gestureRecognizer.isEnabled = navigationController.viewControllers.count > 1
        }
    }

    func restoreInteractivePopGestureDelegate() {
        guard installedGestureRecognizer?.delegate === popGestureDelegate else {
            return
        }

        installedGestureRecognizer?.delegate = originalGestureDelegate
    }
}

private final class SoomsilInteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController else {
            return false
        }

        return navigationController.viewControllers.count > 1
            && navigationController.transitionCoordinator == nil
    }
}
