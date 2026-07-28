import Foundation

enum AcademicSemester: String, CaseIterable, Hashable, Sendable {
    case first
    case summer
    case second
    case winter

    var localizedName: String {
        switch self {
        case .first:
            L10n.AcademicSemester.first
        case .summer:
            L10n.AcademicSemester.summer
        case .second:
            L10n.AcademicSemester.second
        case .winter:
            L10n.AcademicSemester.winter
        }
    }

    var sortOrder: Int {
        switch self {
        case .first: 0
        case .summer: 1
        case .second: 2
        case .winter: 3
        }
    }
}

struct StudentProfile: Sendable {
    let name: String
    let department: String
    let studentID: String
    let email: String
    let academicYear: String?
    let enrollmentStatus: String?

    init(
        name: String,
        department: String,
        studentID: String,
        email: String,
        academicYear: String? = nil,
        enrollmentStatus: String? = nil
    ) {
        self.name = name
        self.department = department
        self.studentID = studentID
        self.email = email
        self.academicYear = academicYear
        self.enrollmentStatus = enrollmentStatus
    }
}

struct SemesterGrade: Identifiable, Sendable {
    var id: String { "\(year)-\(semester.rawValue)" }

    let year: String
    let semester: AcademicSemester
    let attemptedCredits: Double
    let gpa: Double
    let earnedCredits: Double
    let passFailCredits: Double
    let gradePointSum: Double
    let arithmeticMean: Double
    let semesterRank: String
    let totalRank: String
    let academicWarning: String
    let consultationStatus: String
    let failedYearStatus: String

    /// GPA에 실제로 반영된 학점입니다. 신청 학점에서 P/F 학점을 제외해
    /// F 과목이 포함된 경우에도 누적 평점 분모를 보존합니다.
    var gradedCredits: Double {
        let attemptedGradedCredits = max(attemptedCredits - passFailCredits, 0)
        if attemptedGradedCredits > 0 {
            return attemptedGradedCredits
        }
        if gpa > 0, gradePointSum > 0 {
            return gradePointSum / gpa
        }
        return 0
    }
}

struct CourseGrade: Identifiable, Sendable {
    var id: String { courseCode }

    let courseCode: String
    let title: String
    let classification: String
    let credits: Double
    let grade: String
    let gradePoint: String
    let professor: String
}

struct ChapelStatus: Sendable {
    let year: String
    let semester: AcademicSemester
    let classGroup: String
    let timetable: String
    let seat: String
    let classroom: String
    let absenceCount: String
    let gradeResult: String
    let attendance: [ChapelAttendance]
}

struct ChapelAttendance: Identifiable, Sendable {
    var id: String { "\(date)-\(classGroup)-\(lectureType)" }

    let date: String
    let classGroup: String
    let lectureType: String
    let status: ChapelAttendanceStatus
}

enum ChapelAttendanceStatus: Equatable, Sendable {
    case present
    case absent
    case late
    case excused
    case unknown(String)

    init(serverValue: String) {
        let value = serverValue.trimmingCharacters(in: .whitespacesAndNewlines)
        switch value.lowercased() {
        case "출석", "present", "attendance":
            self = .present
        case "미출석", "결석", "absent", "absence":
            self = .absent
        case "지각", "late":
            self = .late
        case "공결", "excused":
            self = .excused
        default:
            self = .unknown(value)
        }
    }

    var isPresent: Bool {
        self == .present
    }

    var localizedName: String {
        switch self {
        case .present:
            L10n.Attendance.present
        case .absent:
            L10n.Attendance.absent
        case .late:
            L10n.Attendance.late
        case .excused:
            L10n.Attendance.excused
        case let .unknown(value):
            value.isEmpty ? L10n.Attendance.unknown : value
        }
    }
}

struct Dashboard: Sendable {
    let profile: StudentProfile
    let semesters: [SemesterGrade]
    let currentCourses: [CourseGrade]
    let chapel: ChapelStatus?
    let chapelErrorMessage: String?

    var latestSemester: SemesterGrade? {
        semesters.max {
            let lhs = (Int($0.year) ?? 0, $0.semester.sortOrder)
            let rhs = (Int($1.year) ?? 0, $1.semester.sortOrder)
            return lhs < rhs
        }
    }

    var cumulativeGPA: Double {
        let gradePointSum = semesters.reduce(0) { $0 + $1.gradePointSum }
        let gradedCredits = semesters.reduce(0) { $0 + $1.gradedCredits }
        guard gradedCredits > 0 else { return 0 }
        return gradePointSum / gradedCredits
    }

    var cumulativeEarnedCredits: Double {
        semesters.reduce(0) { $0 + $1.earnedCredits }
    }
}
