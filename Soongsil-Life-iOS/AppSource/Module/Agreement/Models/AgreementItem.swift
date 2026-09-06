import Foundation

enum AgreementItem: String, CaseIterable, Identifiable, Hashable {
    case terms
    case privacy
    case marketing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms:
            L10n.Agreement.terms
        case .privacy:
            L10n.Agreement.privacy
        case .marketing:
            L10n.Agreement.marketing
        }
    }

    var legalDocumentKind: LegalDocumentKind? {
        switch self {
        case .terms:
            .terms
        case .privacy:
            .privacy
        case .marketing:
            nil
        }
    }

    static var visibleItems: [AgreementItem] {
        allCases.filter { item in
            item != .marketing || AppFeatureAvailability.showsMarketingAgreement
        }
    }
}
