import Foundation

enum MockLMSFixtures {
    static let profile = StudentProfile(
        name: "김숨실",
        department: "글로벌미디어학부",
        studentID: "20201234",
        email: "soomsil@soongsil.ac.kr",
        academicYear: L10n.Home.mockAcademicYear,
        enrollmentStatus: L10n.Home.mockEnrollmentStatus
    )

    static let semesters = [
        semesterGrade(
            year: "2023",
            semester: .first,
            attemptedCredits: 18,
            earnedCredits: 18,
            gpa: 3.70,
            gradePointSum: 66.60,
            semesterRank: "18/120",
            totalRank: "35/240"
        ),
        semesterGrade(
            year: "2023",
            semester: .second,
            attemptedCredits: 18,
            earnedCredits: 18,
            gpa: 3.85,
            gradePointSum: 69.30,
            semesterRank: "14/118",
            totalRank: "29/238"
        ),
        semesterGrade(
            year: "2024",
            semester: .first,
            attemptedCredits: 19.5,
            earnedCredits: 19.5,
            gpa: 4.12,
            gradePointSum: 80.34,
            semesterRank: "8/116",
            totalRank: "20/232"
        ),
        semesterGrade(
            year: "2024",
            semester: .second,
            attemptedCredits: 18,
            earnedCredits: 18,
            gpa: 3.92,
            gradePointSum: 70.56,
            semesterRank: "11/114",
            totalRank: "18/228"
        ),
        semesterGrade(
            year: "2025",
            semester: .first,
            attemptedCredits: 18,
            earnedCredits: 17.5,
            passFailCredits: 0.5,
            gpa: 4.22,
            gradePointSum: 73.85,
            semesterRank: "5/110",
            totalRank: "12/220"
        )
    ]

    static let courses = [
        CourseGrade(courseCode: "CHAPEL", title: "비전채플", classification: "교양필수", credits: 0.5, grade: "P", gradePoint: "0", professor: "박영수"),
        CourseGrade(courseCode: "GM001", title: "디지털미디어원리", classification: "전공기초", credits: 3, grade: "A+", gradePoint: "4.5", professor: "김서연"),
        CourseGrade(courseCode: "CS201", title: "데이터베이스", classification: "전공선택", credits: 3, grade: "A0", gradePoint: "4.0", professor: "한지훈"),
        CourseGrade(courseCode: "CS204", title: "알고리즘", classification: "전공선택", credits: 3, grade: "B+", gradePoint: "3.5", professor: "한유진"),
        CourseGrade(courseCode: "CS301", title: "소프트웨어공학", classification: "전공선택", credits: 3, grade: "A+", gradePoint: "4.5", professor: "윤서현")
    ]

    static let coursesBySemester: [SemesterGrade.ID: [CourseGrade]] = Dictionary(
        uniqueKeysWithValues: semesters.map { semester in
            (semester.id, courses)
        }
    )

    static let chapel = ChapelStatus(
        year: "2025",
        semester: .first,
        classGroup: "20250001",
        timetable: "목요일 10:30",
        seat: "B-12",
        classroom: "한경직기념관 대예배실",
        absenceCount: "1",
        gradeResult: "P",
        attendance: [
            ChapelAttendance(date: "2025.03.13", classGroup: "20250001", lectureType: "채플", status: .present),
            ChapelAttendance(date: "2025.03.20", classGroup: "20250001", lectureType: "채플", status: .present),
            ChapelAttendance(date: "2025.03.27", classGroup: "20250001", lectureType: "채플", status: ChapelAttendanceStatus(serverValue: "미출석")),
            ChapelAttendance(date: "2025.04.03", classGroup: "20250001", lectureType: "채플", status: .present),
            ChapelAttendance(date: "2025.04.10", classGroup: "20250001", lectureType: "채플", status: .present)
        ]
    )

    static let tuitionRecords = [
        TuitionRecord(year: "2022학년도", semester: .first, grade: "1", registrationType: "학기등록", registrationDate: "2022.02.09", amount: "1,000,000", reduction: "0,000", paymentAmount: "1,000,000"),
        TuitionRecord(year: "2022학년도", semester: .second, grade: "1", registrationType: "학기등록", registrationDate: "2022.08.24", amount: "1,000,000", reduction: "0", paymentAmount: "1,000,000"),
        TuitionRecord(year: "2023학년도", semester: .first, grade: "2", registrationType: "학기등록", registrationDate: "2023.02.20", amount: "2,750,000", reduction: "1,750,000", paymentAmount: "1,000,000"),
        TuitionRecord(year: "2023학년도", semester: .second, grade: "2", registrationType: "학기등록", registrationDate: "2023.08.23", amount: "1,000,000", reduction: "0,000", paymentAmount: "1,000,000"),
        TuitionRecord(year: "2024학년도", semester: .first, grade: "3", registrationType: "학기등록", registrationDate: "2024.02.23", amount: "1,000,000", reduction: "0", paymentAmount: "1,000,000"),
        TuitionRecord(year: "2024학년도", semester: .second, grade: "3", registrationType: "학기등록", registrationDate: "2024.08.26", amount: "1,000,000", reduction: "0", paymentAmount: "1,000,000"),
        TuitionRecord(year: "2026학년도", semester: .summer, grade: "4", registrationType: "학기등록", registrationDate: "2026.02.26", amount: "1,000,000", reduction: "0", paymentAmount: "1,000,000")
    ]

    static let scholarshipRecords = [
        ScholarshipRecord(year: "2026", semester: .first, scholarshipName: "한국장학재단(국가장학금II유형)", paymentMethod: "", processStatus: "선발탈락", note: "", dropReason: "소득분위 초과", processDate: "2026.02.04", selectedAmount: "0", actualAmount: "0", redeemedAmount: "0", replacedAmount: "0", replacedScholarshipName: "", workDepartment: ""),
        ScholarshipRecord(year: "2024", semester: .second, scholarshipName: "한국장학재단(국가장학금II유형)", paymentMethod: "", processStatus: "선발탈락", note: "", dropReason: "소득구간 초과", processDate: "2024.07.30", selectedAmount: "0", actualAmount: "0", redeemedAmount: "0", replacedAmount: "0", replacedScholarshipName: "", workDepartment: ""),
        ScholarshipRecord(year: "2024", semester: .first, scholarshipName: "한국장학재단(국가장학금II유형)", paymentMethod: "", processStatus: "선발탈락", note: "", dropReason: "소득구간 초과", processDate: "2024.01.29", selectedAmount: "0", actualAmount: "0", redeemedAmount: "0", replacedAmount: "0", replacedScholarshipName: "", workDepartment: ""),
        ScholarshipRecord(year: "2023", semester: .second, scholarshipName: "한국장학재단(국가장학금II유형)", paymentMethod: "", processStatus: "지급완료", note: "", dropReason: "", processDate: "2023.09.01", selectedAmount: "0,000,000", actualAmount: "0,000,000", redeemedAmount: "0", replacedAmount: "0", replacedScholarshipName: "", workDepartment: ""),
        ScholarshipRecord(year: "2023", semester: .second, scholarshipName: "한국장학재단(국가장학금II유형) 우대지원", paymentMethod: "", processStatus: "선발탈락", note: "", dropReason: "소득구간 초과", processDate: "2023.08.08", selectedAmount: "0", actualAmount: "0", redeemedAmount: "0", replacedAmount: "0", replacedScholarshipName: "", workDepartment: ""),
        ScholarshipRecord(year: "2023", semester: .first, scholarshipName: "한국장학재단(국가장학금II유형)", paymentMethod: "", processStatus: "지급완료", note: "", dropReason: "", processDate: "2023.03.01", selectedAmount: "0,000,000", actualAmount: "0,000,000", redeemedAmount: "0", replacedAmount: "0", replacedScholarshipName: "", workDepartment: ""),
        ScholarshipRecord(year: "2022", semester: .second, scholarshipName: "학과(부)우수장학금", paymentMethod: "", processStatus: "지급완료", note: "[융특]학과우수장학금", dropReason: "", processDate: "2023.02.14", selectedAmount: "100,000", actualAmount: "100,000", redeemedAmount: "0", replacedAmount: "0", replacedScholarshipName: "", workDepartment: "")
    ]

    static let graduationAudit = GraduationAudit(
        items: [
            GraduationAuditItem(
                classification: .graduationRequired,
                requirement: "총 취득학점",
                standardValue: "133",
                calculatedValue: "136",
                difference: "+3",
                status: .satisfied,
                usedSubjects: []
            ),
            GraduationAuditItem(
                classification: .liberalArtsRequired,
                requirement: "교양필수",
                standardValue: "14",
                calculatedValue: "14",
                difference: "0",
                status: .satisfied,
                usedSubjects: [
                    "컴퓨팅적사고",
                    "Academic and Professional English 1",
                    "한반도평화와통일"
                ]
            ),
            GraduationAuditItem(
                classification: .liberalArtsElective,
                requirement: "교양선택",
                standardValue: "20",
                calculatedValue: "22",
                difference: "+2",
                status: .satisfied,
                usedSubjects: ["현대사회와윤리", "과학기술과사회"]
            ),
            GraduationAuditItem(
                classification: .majorBasic,
                requirement: "전공기초",
                standardValue: "12",
                calculatedValue: "12",
                difference: "0",
                status: .satisfied,
                usedSubjects: ["프로그래밍기초및실습", "디지털미디어원리"]
            ),
            GraduationAuditItem(
                classification: .major,
                requirement: "전공학점",
                standardValue: "60",
                calculatedValue: "57",
                difference: "-3",
                status: .insufficient,
                usedSubjects: ["데이터베이스", "알고리즘", "소프트웨어공학"]
            ),
            GraduationAuditItem(
                classification: .chapel,
                requirement: "채플",
                standardValue: "6",
                calculatedValue: "6",
                difference: "0",
                status: .satisfied,
                usedSubjects: ["비전채플"]
            ),
            GraduationAuditItem(
                classification: .other("복수전공"),
                requirement: "복수전공 이수학점",
                standardValue: "36",
                calculatedValue: "36",
                difference: "0",
                status: .satisfied,
                usedSubjects: ["모바일프로그래밍"]
            )
        ]
    )

    static let dashboard = Dashboard(
        profile: profile,
        semesters: semesters,
        currentCourses: courses,
        chapel: chapel,
        chapelErrorMessage: nil
    )

    static func semesterID(
        year: String,
        semester: AcademicSemester
    ) -> SemesterGrade.ID {
        "\(year)-\(semester.rawValue)"
    }

    private static func semesterGrade(
        year: String,
        semester: AcademicSemester,
        attemptedCredits: Double,
        earnedCredits: Double,
        passFailCredits: Double = 0,
        gpa: Double,
        gradePointSum: Double,
        semesterRank: String,
        totalRank: String
    ) -> SemesterGrade {
        SemesterGrade(
            year: year,
            semester: semester,
            attemptedCredits: attemptedCredits,
            gpa: gpa,
            earnedCredits: earnedCredits,
            passFailCredits: passFailCredits,
            gradePointSum: gradePointSum,
            arithmeticMean: gpa / 4.5 * 100,
            semesterRank: semesterRank,
            totalRank: totalRank,
            academicWarning: "N",
            consultationStatus: "완료",
            failedYearStatus: "N"
        )
    }
}
