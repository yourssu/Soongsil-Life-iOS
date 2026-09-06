import Foundation

enum LegalDocumentKind: Hashable, Identifiable {
    case terms
    case privacy

    var id: String {
        switch self {
        case .terms:
            "terms"
        case .privacy:
            "privacy"
        }
    }

    var title: String {
        switch self {
        case .terms:
            L10n.Settings.terms
        case .privacy:
            L10n.Settings.privacy
        }
    }

    var url: URL {
        switch self {
        case .terms:
            AppConfig.termsURL
        case .privacy:
            AppConfig.privacyURL
        }
    }

    var document: LegalDocument {
        switch self {
        case .terms:
            .terms
        case .privacy:
            .privacy
        }
    }
}

struct LegalDocument {
    let title: String
    let effectiveDate: String
    let introduction: String
    let sections: [LegalDocumentSection]
}

struct LegalDocumentSection: Identifiable {
    let id: String
    let title: String
    let body: String
}

private extension LegalDocument {
    static let terms = LegalDocument(
        title: L10n.Settings.terms,
        effectiveDate: L10n.Legal.effectiveDate,
        introduction: L10n.Legal.Terms.introduction,
        sections: [
            LegalDocumentSection(
                id: "service",
                title: L10n.Legal.Terms.serviceTitle,
                body: L10n.Legal.Terms.serviceBody
            ),
            LegalDocumentSection(
                id: "account",
                title: L10n.Legal.Terms.accountTitle,
                body: L10n.Legal.Terms.accountBody
            ),
            LegalDocumentSection(
                id: "usage",
                title: L10n.Legal.Terms.usageTitle,
                body: L10n.Legal.Terms.usageBody
            ),
            LegalDocumentSection(
                id: "accuracy",
                title: L10n.Legal.Terms.accuracyTitle,
                body: L10n.Legal.Terms.accuracyBody
            ),
            LegalDocumentSection(
                id: "availability",
                title: L10n.Legal.Terms.availabilityTitle,
                body: L10n.Legal.Terms.availabilityBody
            ),
            LegalDocumentSection(
                id: "changes",
                title: L10n.Legal.Terms.changesTitle,
                body: L10n.Legal.Terms.changesBody
            ),
            LegalDocumentSection(
                id: "contact",
                title: L10n.Legal.contactTitle,
                body: L10n.Legal.contactBody
            )
        ]
    )

    static let privacy = LegalDocument(
        title: L10n.Settings.privacy,
        effectiveDate: L10n.Legal.effectiveDate,
        introduction: L10n.Legal.Privacy.introduction,
        sections: [
            LegalDocumentSection(
                id: "data",
                title: L10n.Legal.Privacy.dataTitle,
                body: L10n.Legal.Privacy.dataBody
            ),
            LegalDocumentSection(
                id: "purpose",
                title: L10n.Legal.Privacy.purposeTitle,
                body: L10n.Legal.Privacy.purposeBody
            ),
            LegalDocumentSection(
                id: "transmission",
                title: L10n.Legal.Privacy.transmissionTitle,
                body: L10n.Legal.Privacy.transmissionBody
            ),
            LegalDocumentSection(
                id: "retention",
                title: L10n.Legal.Privacy.retentionTitle,
                body: L10n.Legal.Privacy.retentionBody
            ),
            LegalDocumentSection(
                id: "third-party",
                title: L10n.Legal.Privacy.thirdPartyTitle,
                body: L10n.Legal.Privacy.thirdPartyBody
            ),
            LegalDocumentSection(
                id: "rights",
                title: L10n.Legal.Privacy.rightsTitle,
                body: L10n.Legal.Privacy.rightsBody
            ),
            LegalDocumentSection(
                id: "security",
                title: L10n.Legal.Privacy.securityTitle,
                body: L10n.Legal.Privacy.securityBody
            ),
            LegalDocumentSection(
                id: "changes",
                title: L10n.Legal.Privacy.changesTitle,
                body: L10n.Legal.Privacy.changesBody
            ),
            LegalDocumentSection(
                id: "contact",
                title: L10n.Legal.contactTitle,
                body: L10n.Legal.contactBody
            )
        ]
    )
}
