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
    
    static let graduateTable = GraduationAudit(
        items: [
            GraduationAuditItem(
                classification: "졸업필수 요건",
                requirement: "학부-졸업학점 133",
                standardValue: "133",
                calculatedValue: "131.0",
                difference: "-2.0",
                result: "부족"
            ),
            GraduationAuditItem(
                classification: "졸업필수 요건",
                requirement: "학부-편입 요이수 지정과목",
                standardValue: "",
                calculatedValue: "",
                difference: "",
                result: "충족"
            ),
            GraduationAuditItem(
                classification: "졸업필수 요건",
                requirement: "학부-졸업논문/졸업시험 이수",
                standardValue: "",
                calculatedValue: "",
                difference: "",
                result: "부족"
            ),
            GraduationAuditItem(
                classification: "졸업필수 요건",
                requirement: "학부-졸업확정신고 여부",
                standardValue: "",
                calculatedValue: "",
                difference: "",
                result: "부족"
            ),
            GraduationAuditItem(
                classification: "졸업필수 요건",
                requirement: "학부-기독교과목 3학점 이상 (23 이후)",
                standardValue: "3",
                calculatedValue: "1.0",
                difference: "-2.0",
                result: "부족"
            ),

            GraduationAuditItem(
                classification: "교양필수",
                requirement: "학부-교양필수 19",
                standardValue: "19",
                calculatedValue: "4.0",
                difference: "-15.0",
                result: "부족"
            ),

            GraduationAuditItem(
                classification: "교양선택",
                requirement: "Balance (교양선택) 3개 영역 이상 이수",
                standardValue: "",
                calculatedValue: "",
                difference: "",
                result: "충족"
            ),
            GraduationAuditItem(
                classification: "교양선택",
                requirement: "학부-교양선택 9",
                standardValue: "9",
                calculatedValue: "7.0",
                difference: "-2.0",
                result: "부족"
            ),

            GraduationAuditItem(
                classification: "전공기초",
                requirement: "학부-전기-AI소프트 12",
                standardValue: "12",
                calculatedValue: "6.0",
                difference: "-6.0",
                result: "부족"
            ),

            GraduationAuditItem(
                classification: "전공",
                requirement: "학부-전필-AI소프트 12",
                standardValue: "12",
                calculatedValue: "",
                difference: "-12.0",
                result: "부족"
            ),
            GraduationAuditItem(
                classification: "전공",
                requirement: "학부-전필+전선-AI소프트 72",
                standardValue: "72",
                calculatedValue: "3.0",
                difference: "-69.0",
                result: "부족"
            ),

            GraduationAuditItem(
                classification: "채플",
                requirement: "학부-채플(신입 6회, 편입2혹은4회)",
                standardValue: "",
                calculatedValue: "",
                difference: "",
                result: "부족"
            )
        ]
    )

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
