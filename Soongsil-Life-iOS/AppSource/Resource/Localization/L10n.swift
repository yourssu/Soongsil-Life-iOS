import Foundation

enum L10n {
    enum Common {
        static let home = text("common.home")
        static let timetable = text("common.timetable")
        static let settings = text("common.settings")
        static let my = text("common.my")
        static let confirm = text("common.confirm")
        static let retry = text("common.retry")
    }

    enum Login {
        static let title = text("login.title")
        static let subtitle = text("login.subtitle")
        static let studentID = text("login.student_id")
        static let password = text("login.password")
        static let action = text("login.action")
        static let unofficialNotice = text("login.unofficial_notice")
        static let credentialNotice = text("login.credential_notice")
    }

    enum Session {
        static let restoringTitle = text("session.restoring_title")
        static let restoringDescription = text("session.restoring_description")
        static let restoreFailedTitle = text("session.restore_failed_title")
        static let retry = text("session.retry")
        static let useAnotherAccount = text("session.use_another_account")
        static let changingAccount = text("session.changing_account")
    }

    enum Home {
        static let loading = text("home.loading")
        static let loadFailed = text("home.load_failed")
        static let retryDescription = text("home.retry_description")
        static let latestGrade = text("home.latest_grade")
        static let chapel = text("home.chapel")
        static let shortcuts = text("home.shortcuts")
        static let graduationAudit = text("home.graduation_audit")
        static let tuitionScholarship = text("home.tuition_scholarship")
        static let mockAcademicYear = text("home.mock_academic_year")
        static let mockEnrollmentStatus = text("home.mock_enrollment_status")
        static let refreshFailed = text("home.refresh_failed")

        static func greeting(_ name: String) -> String {
            format("home.greeting", name)
        }

        static func studentID(_ studentID: String) -> String {
            format("home.student_id", studentID)
        }

        static func profileSubtitle(department: String, studentID: String) -> String {
            format("home.profile_subtitle", department, studentID)
        }

        static func gradeCaption(year: String, semester: String, credits: Double) -> String {
            format("home.grade_caption", year, semester, credits)
        }

        static func chapelCaption(classroom: String, absences: String) -> String {
            format("home.chapel_caption", classroom, absences)
        }
    }

    enum Grades {
        static let title = text("grades.title")
        static let semesterSection = text("grades.semester_section")
        static let courseSection = text("grades.course_section")
        static let includeSeasonalSemesters = text("grades.include_seasonal_semesters")
        static let summerAxis = text("grades.summer_axis")
        static let winterAxis = text("grades.winter_axis")
        static let noSemesterGrades = text("grades.no_semester_grades")
        static let noSemesterGradesDescription = text("grades.no_semester_grades_description")
        static let noCoursesDescription = text("grades.no_courses_description")
        static let noCurrentCoursesDescription = text("grades.no_current_courses_description")

        static func semesterTitle(year: String, semester: String) -> String {
            format("grades.semester_title", year, semester)
        }

        static func semesterDetail(credits: Double, rank: String) -> String {
            format("grades.semester_detail", credits, rank)
        }

        static func courseDetail(professor: String, credits: Double) -> String {
            format("grades.course_detail", professor, credits)
        }
    }

    enum Chapel {
        static let title = text("chapel.title")
        static let loading = text("chapel.loading")
        static let semester = text("chapel.semester")
        static let absences = text("chapel.absences")
        static let attendanceSection = text("chapel.attendance_section")
        static let leftDirection = text("chapel.left_direction")
        static let rightDirection = text("chapel.right_direction")
        static let seatGuideDefault = text("chapel.seat_guide_default")
        static let loadFailed = text("chapel.load_failed")

        static func semesterValue(year: String, semester: String) -> String {
            format("chapel.semester_value", year, semester)
        }

        static func absenceCount(_ count: String) -> String {
            format("chapel.absence_count", count)
        }

        static func seatGuide(
            entranceDirection: String,
            row: Int?,
            seatIndexFromEntrance: Int?
        ) -> String {
            guard let row, let seatIndexFromEntrance else {
                return seatGuideDefault
            }

            return format(
                "chapel.seat_guide",
                entranceDirection,
                ordinal(row),
                ordinal(seatIndexFromEntrance)
            )
        }

        static func seatAccessibilityLabel(
            zone: String,
            row: Int,
            column: Int
        ) -> String {
            format(
                "chapel.seat_accessibility_label",
                zone,
                row,
                column
            )
        }

        private static func ordinal(_ number: Int) -> String {
            guard (1...10).contains(number) else {
                return format("chapel.seat_ordinal_format", number)
            }
            return text("chapel.seat_ordinal_\(number)")
        }
    }

    enum Timetable {
        static let title = text("timetable.title")
        static let loadFailed = text("timetable.load_failed")
        static let loading = text("timetable.loading")
        static let empty = text("timetable.empty")
        static let emptyDescription = text("timetable.empty_description")
        static let close = text("timetable.close")
        static let time = text("timetable.time")
        static let professor = text("timetable.professor")
        static let classroom = text("timetable.classroom")
        static let periodFilter = text("timetable.period_filter")

        static func academicYear(_ year: String) -> String {
            format("timetable.academic_year", year)
        }

        static func periodTitle(year: String, semester: String) -> String {
            format("timetable.period_title", year, semester)
        }

        static func period(day: String, period: Int) -> String {
            format("timetable.period", day, period)
        }
    }

    enum Tuition {
        static let tuitionTab = text("tuition.tuition_tab")
        static let scholarshipTab = text("tuition.scholarship_tab")
        static let noTuitionRecords = text("tuition.no_tuition_records")
        static let noScholarshipRecords = text("tuition.no_scholarship_records")
        static let retry = text("tuition.retry")
        static let tuitionDate = text("tuition.tuition_date")
        static let reduction = text("tuition.reduction")
        static let loadFailed = text("tuition.load_failed")
    }

    enum AcademicSemester {
        static let first = text("academic_semester.first")
        static let summer = text("academic_semester.summer")
        static let second = text("academic_semester.second")
        static let winter = text("academic_semester.winter")
    }

    enum Attendance {
        static let present = text("attendance.present")
        static let absent = text("attendance.absent")
        static let late = text("attendance.late")
        static let excused = text("attendance.excused")
        static let unknown = text("attendance.unknown")
    }

    enum GraduationAudit {
        static let graduationRequired = text("graduation_audit.graduation_required")
        static let liberalArtsRequired = text("graduation_audit.liberal_arts_required")
        static let liberalArtsElective = text("graduation_audit.liberal_arts_elective")
        static let majorBasic = text("graduation_audit.major_basic")
        static let major = text("graduation_audit.major")
        static let chapel = text("graduation_audit.chapel")
        static let other = text("graduation_audit.other")
        static let result = text("graduation_audit.result")
        static let eligible = text("graduation_audit.eligible")
        static let ineligible = text("graduation_audit.ineligible")
        static let satisfied = text("graduation_audit.satisfied")
        static let insufficient = text("graduation_audit.insufficient")
        static let unknownStatus = text("graduation_audit.unknown_status")
        static let hideCourseStatus = text("graduation_audit.hide_course_status")
        static let showCourseStatus = text("graduation_audit.show_course_status")
        static let standard = text("graduation_audit.standard")
        static let calculated = text("graduation_audit.calculated")
        static let loading = text("graduation_audit.loading")
        static let emptyTitle = text("graduation_audit.empty_title")
        static let emptyDescription = text("graduation_audit.empty_description")
        static let loadFailed = text("graduation_audit.load_failed")
        static let notice = text("graduation_audit.notice")
    }

    enum Settings {
        static let serviceSection = text("settings.service_section")
        static let terms = text("settings.terms")
        static let privacy = text("settings.privacy")
        static let openSource = text("settings.open_source")
        static let openSourceDescription = text("settings.open_source.description")
        static let openSourceRepository = text("settings.open_source.repository")
        static let openSourceLicense = text("settings.open_source.license")
        static let openSourceLoadFailed = text("settings.open_source.load_failed")
        static let appInfoSection = text("settings.app_info_section")
        static let version = text("settings.version")
        static let logout = text("settings.logout")
        static let logoutConfirmation = text("settings.logout_confirmation")
        static let logoutFailed = text("settings.logout_failed")
    }

    enum Legal {
        static let effectiveDate = text("legal.effective_date")
        static let contactTitle = text("legal.contact_title")
        static let contactBody = text("legal.contact_body")

        enum Terms {
            static let introduction = text("legal.terms.introduction")
            static let serviceTitle = text("legal.terms.service_title")
            static let serviceBody = text("legal.terms.service_body")
            static let accountTitle = text("legal.terms.account_title")
            static let accountBody = text("legal.terms.account_body")
            static let usageTitle = text("legal.terms.usage_title")
            static let usageBody = text("legal.terms.usage_body")
            static let accuracyTitle = text("legal.terms.accuracy_title")
            static let accuracyBody = text("legal.terms.accuracy_body")
            static let availabilityTitle = text("legal.terms.availability_title")
            static let availabilityBody = text("legal.terms.availability_body")
            static let changesTitle = text("legal.terms.changes_title")
            static let changesBody = text("legal.terms.changes_body")
        }

        enum Privacy {
            static let introduction = text("legal.privacy.introduction")
            static let dataTitle = text("legal.privacy.data_title")
            static let dataBody = text("legal.privacy.data_body")
            static let purposeTitle = text("legal.privacy.purpose_title")
            static let purposeBody = text("legal.privacy.purpose_body")
            static let transmissionTitle = text("legal.privacy.transmission_title")
            static let transmissionBody = text("legal.privacy.transmission_body")
            static let retentionTitle = text("legal.privacy.retention_title")
            static let retentionBody = text("legal.privacy.retention_body")
            static let thirdPartyTitle = text("legal.privacy.third_party_title")
            static let thirdPartyBody = text("legal.privacy.third_party_body")
            static let rightsTitle = text("legal.privacy.rights_title")
            static let rightsBody = text("legal.privacy.rights_body")
            static let securityTitle = text("legal.privacy.security_title")
            static let securityBody = text("legal.privacy.security_body")
            static let changesTitle = text("legal.privacy.changes_title")
            static let changesBody = text("legal.privacy.changes_body")
        }
    }

    enum Soomsil {
        static let loginHeading = text("soomsil.login_heading")
        static let loginDescription = text("soomsil.login_description")
        static let reportCardTitle = text("soomsil.report_card_title")
        static let total = text("soomsil.total")
        static let currentSemesterGrades = text("soomsil.current_semester_grades")
        static let gpaTrend = text("soomsil.gpa_trend")
        static let overallSemesterTrend = text("soomsil.overall_semester_trend")
        static let details = text("soomsil.details")
        static let chapelAttendance = text("soomsil.chapel_attendance")
        static let remainingAttendance = text("soomsil.remaining_attendance")
        static let mySeat = text("soomsil.my_seat")
        static let seatLocation = text("soomsil.seat_location")
        static let cancel = text("soomsil.cancel")
        static let account = text("soomsil.account")
        static let agreements = text("soomsil.agreements")
        static let versionInfo = text("soomsil.version_info")
        static let logoutTitle = text("soomsil.logout_title")
        static let logoutMessage = text("soomsil.logout_message")
        static let noChapelTitle = text("soomsil.no_chapel_title")
        static let noChapel = text("soomsil.no_chapel")
        static let notTakingChapelTitle = text("soomsil.not_taking_chapel_title")
        static let notTakingChapel = text("soomsil.not_taking_chapel")
        static let chapelInfo = text("soomsil.chapel_info")
        static let selectedSeat = text("soomsil.selected_seat")
        static let stage = text("soomsil.stage")
        static let totalGPA = text("soomsil.total_gpa")
        static let earnedCredits = text("soomsil.earned_credits")
        static let courses = text("soomsil.courses")

        static func greeting(_ name: String) -> String {
            format("soomsil.greeting", name)
        }

        static func attendanceSummary(_ attendance: Int, _ required: Int) -> String {
            format("soomsil.attendance_summary", attendance, required)
        }

        static func attendanceCount(_ attendance: Int, _ required: Int) -> String {
            format("soomsil.attendance_count", attendance, required)
        }

        static func attendanceDetail(
            attendance: Int,
            late: Int,
            percentage: Int
        ) -> String {
            format(
                "soomsil.attendance_detail",
                attendance,
                late,
                percentage
            )
        }

        static func chapelSeatDescription(
            classroom: String,
            zone: String
        ) -> String {
            format("soomsil.chapel_seat_description", classroom, zone)
        }

        static func appVersion(_ version: String) -> String {
            format("soomsil.app_version", version)
        }
    }

    enum Error {
        static let loginFailed = text("error.login_failed")
        static let gradesFailed = text("error.grades_failed")
        static let profileFailed = text("error.profile_failed")
        static let semestersFailed = text("error.semesters_failed")
        static let tuitionFailed = text("error.tuition_failed")
        static let scholarshipFailed = text("error.scholarship_failed")
        static let graduateTableFailed = text("error.graduate_table_failed")
        static let invalidResponse = text("error.invalid_response")
        static let networkUnavailable = text("error.network_unavailable")
        static let requestTimedOut = text("error.request_timed_out")
        static let requestCancelled = text("error.request_cancelled")
        static let noSavedCredentials = text("error.no_saved_credentials")
        static let autoLoginStorageFailed = text("error.auto_login_storage_failed")
    }

    private static func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: .main, comment: "")
    }

    private static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
}
