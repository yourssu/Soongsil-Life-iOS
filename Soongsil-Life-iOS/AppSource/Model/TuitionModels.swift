import Foundation

struct TuitionRecord: Identifiable, Sendable {
    var id: String {
        "\(year)-\(semester)-\(registrationType)-\(registrationDate)-\(paymentAmount)"
    }

    let year: String
    let semester: String
    let grade: String
    let registrationType: String
    let registrationDate: String
    let amount: String
    let reduction: String
    let paymentAmount: String
}

struct ScholarshipRecord: Identifiable, Sendable {
    var id: String {
        "\(year)-\(semester)-\(scholarshipName)-\(processDate)-\(actualAmount)"
    }

    let year: String
    let semester: String
    let scholarshipName: String
    let paymentMethod: String
    let processStatus: String
    let note: String
    let dropReason: String
    let processDate: String
    let selectedAmount: String
    let actualAmount: String
    let redeemedAmount: String
    let replacedAmount: String
    let replacedScholarshipName: String
    let workDepartment: String
}
