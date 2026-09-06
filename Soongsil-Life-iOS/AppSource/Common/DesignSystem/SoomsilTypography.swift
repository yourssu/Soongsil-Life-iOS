import CoreText
import SwiftUI

/// The app's single typography entry point.
///
/// Pretendard is registered from the bundled variable-font file on first use so
/// both the application and the preview target render the Figma typography.
enum SoomsilTypography {
    private static let fontName = "PretendardVariable-Regular"

    private static let registerBundledFont: Void = {
        guard let fontURL = Bundle.main.url(
            forResource: "PretendardVariable",
            withExtension: "ttf"
        ) else {
            assertionFailure("PretendardVariable.ttf is missing from the app bundle")
            return
        }

        var registrationError: Unmanaged<CFError>?
        let didRegister = CTFontManagerRegisterFontsForURL(
            fontURL as CFURL,
            .process,
            &registrationError
        )

        if !didRegister,
           let error = registrationError?.takeRetainedValue() as Error?,
           (error as NSError).code != CTFontManagerError.alreadyRegistered.rawValue {
            assertionFailure("Could not register Pretendard: \(error.localizedDescription)")
        }
    }()

    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        _ = registerBundledFont
        return .custom(fontName, size: size).weight(weight)
    }
}

extension Font {
    static func pretendard(
        _ size: CGFloat,
        weight: Font.Weight = .regular
    ) -> Font {
        SoomsilTypography.font(size: size, weight: weight)
    }
}
