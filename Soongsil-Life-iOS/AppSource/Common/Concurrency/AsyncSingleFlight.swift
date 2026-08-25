import Foundation

/// 동일한 비동기 작업이 실행 중이면 새 작업을 만들지 않고 기존 작업의 결과를 기다립니다.
///
/// 내부 작업은 호출한 Task와 수명 주기를 분리해, 화면의 `.task`가 취소되더라도
/// 실제 요청은 계속 진행됩니다.
@MainActor
final class AsyncSingleFlight {
    private var current: (id: UUID, task: Task<Void, Never>)?

    func run(
        operation: @escaping @MainActor @Sendable () async -> Void
    ) async {
        if let task = current?.task {
            return await task.value
        }

        let id = UUID()
        let task = Task { @MainActor in
            await operation()
        }
        current = (id, task)

        await task.value
        if current?.id == id {
            current = nil
        }
    }
}
