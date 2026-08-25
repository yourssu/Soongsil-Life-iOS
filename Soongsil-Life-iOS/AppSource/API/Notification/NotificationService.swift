import Foundation
import LmsApi


final class NotificationService: NotificationServiceProtocol {
    private let api = LmsApi.shared

  
    //학기 불러오는 것이 성공하면 수강과목 리스트 불러오기
    func fetchLatestTermTodoList() async throws -> [CourseTodo] {
        let term = try await fetchLatestTerm()
        return try await fetchTodoList(term: term)
    }


    private func fetchLatestTerm() async throws -> Term {
        try await withCheckedThrowingContinuation { continuation in
            api.getTerms { result in
      
                //최근 학기 정보 불러오기
                //terms는 배열로 오며, 최신순으로 정렬되어있음.
                // ex) [2026년 2학기, 2026년 1학기, 비정규과정(2026), SSU-PATH 연동 학기]
                guard result.success, let term = result.terms.last else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? NotificationStrings.termsFailed
                        )
                    )
                    return
                }
                continuation.resume(returning: term)
            }
        }
    }


    private func fetchTodoList(term: Term) async throws -> [CourseTodo] {
        try await withCheckedThrowingContinuation { continuation in
     
            api.getTodoList(
                term: term,
                loadingState: { _ in },
                postHogDistinctId: nil
            ) { result in
                guard result.success else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? NotificationStrings.todoListFailed
                        )
                    )
                    return
                }
          
                continuation.resume(
                    returning: result.subjects.flatMap { subject in
                        subject.todoList.map { todo in
                            CourseTodo(
                                id: "\(subject.id)-\(todo.component_type)-\(todo.title)",
                                subjectName: subject.name,
                                title: todo.title,
                                kind: CourseTodoKind(componentType: todo.component_type),
                                dueDate: Self.iso8601.date(from: todo.due_date)
                            )
                        }
                    }
                )
            }
        }
    }

    /// `due_date`는 `"2026-03-19T14:59:59Z"` 형태의 문자열이므로 변환이 필요
    private static let iso8601 = ISO8601DateFormatter()
}
