import Foundation

struct GraduationAudit: Sendable {
    let items: [GraduationAuditItem]

    var isGraduatable: Bool {
        !items.isEmpty && items.allSatisfy(\.isSatisfied)
    }

    var hasUsedSubjects: Bool {
        items.contains { !$0.usedSubjects.isEmpty }
    }

    var sections: [GraduationAuditSection] {
        var classifications: [GraduationAuditClassification] = []
        var groupedItems: [GraduationAuditClassification: [GraduationAuditItem]] = [:]

        for item in items {
            if groupedItems[item.classification] == nil {
                classifications.append(item.classification)
            }
            groupedItems[item.classification, default: []].append(item)
        }

        let knownClassifications = GraduationAuditClassification.knownOrder.filter {
            groupedItems[$0] != nil
        }
        let otherClassifications = classifications.filter { !$0.isKnown }

        return (knownClassifications + otherClassifications).compactMap { classification in
            guard let items = groupedItems[classification] else { return nil }
            return GraduationAuditSection(
                classification: classification,
                items: items
            )
        }
    }
}

struct GraduationAuditSection: Identifiable, Sendable {
    var id: GraduationAuditClassification { classification }

    let classification: GraduationAuditClassification
    let items: [GraduationAuditItem]
}

struct GraduationAuditItem: Identifiable, Sendable {
    let id: UUID
    let classification: GraduationAuditClassification
    let requirement: String
    let standardValue: String
    let calculatedValue: String
    let difference: String
    let status: GraduationAuditStatus
    let usedSubjects: [String]

    init(
        id: UUID = UUID(),
        classification: GraduationAuditClassification,
        requirement: String,
        standardValue: String,
        calculatedValue: String,
        difference: String,
        status: GraduationAuditStatus,
        usedSubjects: [String]
    ) {
        self.id = id
        self.classification = classification
        self.requirement = requirement
        self.standardValue = standardValue
        self.calculatedValue = calculatedValue
        self.difference = difference
        self.status = status
        self.usedSubjects = usedSubjects.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var isSatisfied: Bool {
        status == .satisfied
    }
}

enum GraduationAuditClassification: Hashable, Sendable {
    case graduationRequired
    case liberalArtsRequired
    case liberalArtsElective
    case majorBasic
    case major
    case chapel
    case other(String)

    static let knownOrder: [GraduationAuditClassification] = [
        .graduationRequired,
        .liberalArtsRequired,
        .liberalArtsElective,
        .majorBasic,
        .major,
        .chapel
    ]

    init(apiValue: String) {
        let value = apiValue.trimmingCharacters(in: .whitespacesAndNewlines)
        switch value {
        case "졸업필수 요건":
            self = .graduationRequired
        case "교양필수":
            self = .liberalArtsRequired
        case "교양선택":
            self = .liberalArtsElective
        case "전공기초":
            self = .majorBasic
        case "전공":
            self = .major
        case "채플":
            self = .chapel
        default:
            self = .other(value)
        }
    }

    var localizedName: String {
        switch self {
        case .graduationRequired:
            L10n.GraduationAudit.graduationRequired
        case .liberalArtsRequired:
            L10n.GraduationAudit.liberalArtsRequired
        case .liberalArtsElective:
            L10n.GraduationAudit.liberalArtsElective
        case .majorBasic:
            L10n.GraduationAudit.majorBasic
        case .major:
            L10n.GraduationAudit.major
        case .chapel:
            L10n.GraduationAudit.chapel
        case let .other(value):
            value.isEmpty ? L10n.GraduationAudit.other : value
        }
    }

    var isKnown: Bool {
        if case .other = self {
            return false
        }
        return true
    }
}

enum GraduationAuditStatus: Equatable, Sendable {
    case satisfied
    case insufficient

    init?(apiValue: String) {
        let value = apiValue.trimmingCharacters(in: .whitespacesAndNewlines)
        switch value {
        case "충족", "면제", "해당없음", "이수", "통과":
            self = .satisfied
        case "부족", "미이수":
            self = .insufficient
        default:
            return nil
        }
    }

    var localizedName: String {
        switch self {
        case .satisfied:
            L10n.GraduationAudit.satisfied
        case .insufficient:
            L10n.GraduationAudit.insufficient
        }
    }
}
