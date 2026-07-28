import Foundation

protocol StudentServiceProtocol: AnyObject {
    func fetchProfile() async throws -> StudentProfile
}
