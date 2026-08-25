import Foundation
import LmsApi

final class AuthenticationService: AuthenticationServiceProtocol {
    private let api = LmsApi.shared
    private let operationGate = AuthenticationOperationGate()

    var isLoggedIn: Bool {
        api.isLoggined
    }

    func login(id: String, password: String) async throws {
        let operation = try await beginOperation()

        do {
            try await LMSCallbackBridge.call(timeout: .seconds(30)) { completion in
                guard operation.beginSDKRequest() else { return }

                api.loginLMS(id: id, password: password) { result in
                    operation.finishSDKRequest()

                    if result.success {
                        completion(.success(()))
                    } else {
                        completion(
                            .failure(LMSServiceError.serverMessage(
                                raw: result.errorMessage ?? "",
                                fallback: L10n.Error.loginFailed
                            ))
                        )
                    }
                }
            }
        } catch {
            operation.cancelBeforeSDKRequestIfNeeded()
            throw error
        }
    }

    @discardableResult
    func logout() async -> Bool {
        do {
            let operation = try await beginOperation()

            do {
                try await LMSCallbackBridge.call(timeout: .seconds(5)) { completion in
                    guard operation.beginSDKRequest() else { return }

                    api.logout {
                        operation.finishSDKRequest()
                        completion(.success(()))
                    }
                }
                return true
            } catch {
                operation.cancelBeforeSDKRequestIfNeeded()
                return false
            }
        } catch {
            return false
        }
    }

    private func beginOperation() async throws -> AuthenticationSDKOperation {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))

        while clock.now < deadline {
            try Task.checkCancellation()

            if let operation = await operationGate.beginOperation() {
                return operation
            }

            try await Task.sleep(for: .milliseconds(100))
        }

        throw LMSServiceError.requestTimedOut
    }
}

/// LMS SDK가 실제 취소를 제공하지 않으므로, 화면에 timeout을 반환한 뒤에도
/// SDK callback이 올 때까지 다음 인증 요청의 시작을 막습니다.
private actor AuthenticationOperationGate {
    private var activeOperationID: UUID?

    func beginOperation() -> AuthenticationSDKOperation? {
        guard activeOperationID == nil else { return nil }

        let id = UUID()
        activeOperationID = id
        return AuthenticationSDKOperation(id: id, gate: self)
    }

    func finishOperation(id: UUID) {
        guard activeOperationID == id else { return }
        activeOperationID = nil
    }
}

/// caller의 Task와 SDK 요청의 수명을 분리합니다. caller가 timeout 또는 취소되어도
/// 이미 시작된 SDK 요청은 callback 전까지 gate를 점유합니다.
private nonisolated final class AuthenticationSDKOperation: @unchecked Sendable {
    private enum State {
        case ready
        case running
        case finished
    }

    private let lock = NSLock()
    private let id: UUID
    private let gate: AuthenticationOperationGate
    private var state = State.ready

    init(id: UUID, gate: AuthenticationOperationGate) {
        self.id = id
        self.gate = gate
    }

    func beginSDKRequest() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard case .ready = state else { return false }
        state = .running
        return true
    }

    func cancelBeforeSDKRequestIfNeeded() {
        lock.lock()
        guard case .ready = state else {
            lock.unlock()
            return
        }
        state = .finished
        lock.unlock()

        releaseGate()
    }

    func finishSDKRequest() {
        lock.lock()
        guard case .running = state else {
            lock.unlock()
            return
        }
        state = .finished
        lock.unlock()

        releaseGate()
    }

    private func releaseGate() {
        Task { [gate, id] in
            await gate.finishOperation(id: id)
        }
    }
}
