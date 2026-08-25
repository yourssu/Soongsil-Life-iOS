import Foundation
import LmsApi

final class StudentService: StudentServiceProtocol {
    private let api = LmsApi.shared

    func fetchProfile() async throws -> StudentProfile {
        try await LMSCallbackBridge.call { completion in
            api.getLoginInfo { result in
                guard result.success, let info = result.info else {
                    completion(
                        .failure(LMSServiceError.serverMessage(
                            raw: result.errorMessage ?? "",
                            fallback: L10n.Error.profileFailed
                        ))
                    )
                    return
                }
                completion(
                    .success(StudentProfile(
                        name: info.user_name,
                        department: info.dept_name,
                        studentID: info.user_login,
                        email: info.user_email
                    ))
                )
            }
        }
    }
}
