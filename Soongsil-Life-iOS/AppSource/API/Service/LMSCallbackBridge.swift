import Foundation

enum LMSCallbackBridge {
    static func call<Value: Sendable>(
        timeout: Duration = .seconds(20),
        start: (@escaping @Sendable (Result<Value, Error>) -> Void) -> Void
    ) async throws -> Value {
        let clock = ContinuousClock()
        let startedAt = clock.now
        let lease = try await LMSRequestCoordinator.shared.acquire(
            timeout: timeout
        )
        let remainingTimeout = timeout - startedAt.duration(to: clock.now)
        guard remainingTimeout > .zero else {
            lease.release()
            throw LMSServiceError.requestTimedOut
        }

        let state = LMSCallbackState<Value>()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard state.install(continuation) else {
                    lease.release()
                    return
                }

                let timeoutTask = Task {
                    do {
                        try await Task.sleep(for: remainingTimeout)
                    } catch {
                        return
                    }
                    state.resume(
                        with: .failure(LMSServiceError.requestTimedOut)
                    )
                }
                state.setTimeoutTask(timeoutTask)

                // SDK는 Swift Task 취소를 지원하지 않습니다. Swift 쪽 timeout 뒤에도
                // 실제 callback이 도착할 때까지 다음 WebDynpro 요청의 시작을 막습니다.
                // callback이 영구히 오지 않는 경우에만 grace period 뒤 잠금을 풉니다.
                let emergencyReleaseTask = Task {
                    do {
                        try await Task.sleep(
                            for: remainingTimeout + .seconds(15)
                        )
                    } catch {
                        return
                    }
                    lease.release()
                }

                start { [weak state] result in
                    emergencyReleaseTask.cancel()
                    lease.release()
                    state?.resume(with: result)
                }
            }
        } onCancel: {
            state.resume(with: .failure(CancellationError()))
        }
    }
}

/// Kotlin/Native 기반 `LmsApi.shared`는 동시에 여러 WebDynpro 화면을 열 때
/// 내부 세션 메모리를 공유합니다. 모든 SDK 요청을 FIFO로 직렬화해 충돌을 막되,
/// 기다리는 Swift Task 자체는 suspend되어 메인 스레드를 점유하지 않습니다.
private actor LMSRequestCoordinator {
    static let shared = LMSRequestCoordinator()

    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<LMSRequestLease, Error>
    }

    private var isRequestActive = false
    private var waiters: [Waiter] = []

    func acquire(timeout: Duration) async throws -> LMSRequestLease {
        try Task.checkCancellation()

        guard isRequestActive else {
            isRequestActive = true
            return LMSRequestLease(coordinator: self)
        }

        let id = UUID()
        let timeoutTask = Task {
            do {
                try await Task.sleep(for: timeout)
            } catch {
                return
            }
            cancelWaiter(id: id, error: LMSServiceError.requestTimedOut)
        }
        defer { timeoutTask.cancel() }

        let lease = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                waiters.append(Waiter(id: id, continuation: continuation))
            }
        } onCancel: {
            Task {
                await self.cancelWaiter(
                    id: id,
                    error: CancellationError()
                )
            }
        }

        if Task.isCancelled {
            lease.release()
            throw CancellationError()
        }
        return lease
    }

    nonisolated func release() {
        Task { await releaseNext() }
    }

    private func releaseNext() {
        if waiters.isEmpty {
            isRequestActive = false
            return
        }

        let waiter = waiters.removeFirst()
        waiter.continuation.resume(
            returning: LMSRequestLease(coordinator: self)
        )
    }

    private func cancelWaiter(id: UUID, error: Error) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else {
            return
        }

        let waiter = waiters.remove(at: index)
        waiter.continuation.resume(throwing: error)
    }
}

private nonisolated final class LMSRequestLease: @unchecked Sendable {
    private let lock = NSLock()
    private let coordinator: LMSRequestCoordinator
    private var isReleased = false

    init(coordinator: LMSRequestCoordinator) {
        self.coordinator = coordinator
    }

    func release() {
        lock.lock()
        guard !isReleased else {
            lock.unlock()
            return
        }
        isReleased = true
        lock.unlock()

        coordinator.release()
    }
}

private nonisolated final class LMSCallbackState<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?
    private var pendingResult: Result<Value, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var isCompleted = false

    /// 취소가 continuation 설치보다 먼저 도착한 경우에는 즉시 resume하고
    /// 실제 LMS 요청을 시작하지 않습니다.
    func install(
        _ continuation: CheckedContinuation<Value, Error>
    ) -> Bool {
        lock.lock()
        if let pendingResult {
            self.pendingResult = nil
            lock.unlock()
            continuation.resume(with: pendingResult)
            return false
        }

        self.continuation = continuation
        lock.unlock()
        return true
    }

    func setTimeoutTask(_ task: Task<Void, Never>) {
        lock.lock()
        if isCompleted {
            lock.unlock()
            task.cancel()
            return
        }

        timeoutTask = task
        lock.unlock()
    }

    func resume(with result: Result<Value, Error>) {
        lock.lock()
        guard !isCompleted else {
            lock.unlock()
            return
        }

        isCompleted = true
        let continuation = continuation
        self.continuation = nil
        if continuation == nil {
            pendingResult = result
        }
        let timeoutTask = timeoutTask
        self.timeoutTask = nil
        lock.unlock()

        timeoutTask?.cancel()
        continuation?.resume(with: result)
    }
}
