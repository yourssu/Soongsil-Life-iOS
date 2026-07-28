import Foundation
import LmsApi

final class StudentService: StudentServiceProtocol {
    private let api = LmsApi.shared

    func fetchProfile() async throws -> StudentProfile {
        try await withCheckedThrowingContinuation { continuation in
            api.getLoginInfo { result in
                guard result.success, let info = result.info else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.profileFailed
                        )
                    )
                    return
                }
                continuation.resume(
                    returning: StudentProfile(
                        name: info.user_name,
                        department: info.dept_name,
                        studentID: info.user_login,
                        email: info.user_email
                    )
                )
            }
        }
    }
}
