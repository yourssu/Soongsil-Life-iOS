enum ChapelAttendancePolicy {
    static let semesterSessionCount = 8
    static let requiredAttendanceCount = 7

    static var allowedAbsenceCount: Int {
        semesterSessionCount - requiredAttendanceCount
    }

    static func creditedAttendanceCount(
        in attendance: [ChapelAttendance]
    ) -> Int {
        let presentCount = attendance.filter { $0.status == .present }.count
        let excusedCount = attendance.filter { $0.status == .excused }.count
        let lateCount = attendance.filter { $0.status == .late }.count
        let creditedLateCount = lateCount - lateCount / 2

        return min(
            presentCount + excusedCount + creditedLateCount,
            semesterSessionCount
        )
    }

    static func calculatedAbsenceCount(
        in attendance: [ChapelAttendance]
    ) -> Int {
        let absentCount = attendance.filter { $0.status == .absent }.count
        let lateCount = attendance.filter { $0.status == .late }.count
        return absentCount + lateCount / 2
    }
}
