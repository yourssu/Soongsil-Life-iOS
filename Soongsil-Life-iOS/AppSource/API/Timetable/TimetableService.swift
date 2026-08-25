#if !PREVIEW_TARGET && canImport(LmsApi)
import Foundation
import LmsApi

final class TimetableService: TimetableServiceProtocol, @unchecked Sendable {
    private let api = LmsApi.shared
    private let requestTimeout: Duration
    private let maximumFallbackRequests = 3
    private let callbackGate = TimetableSDKRequestGate()

    init(requestTimeout: Duration = .seconds(45)) {
        self.requestTimeout = requestTimeout
    }

    func fetchAvailablePeriods() async throws -> [TimetablePeriod] {
        try await fetchLmsTermPeriods()
    }

    func fetchTimetable(
        for period: TimetablePeriod?
    ) async throws -> TimetableSchedule? {
        if let period {
            return try await requestTimetable(for: period)?.schedule
        }

        // transport/auth/timeout 실패에는 다른 학기를 연속 요청하지 않습니다.
        // Kotlin callback은 timeout 뒤에도 취소되지 않으므로 요청 중첩을 막아야 합니다.
        let initialResponse = try await requestTimetable(for: nil)
        var bestSuccessfulSchedule = initialResponse?.schedule

        let actualPeriods: [TimetablePeriod]
        do {
            actualPeriods = try await fetchLmsTermPeriods()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Self.debugLog("term lookup failed; using calendar fallback")
            actualPeriods = []
        }

        if let initialResponse,
           !initialResponse.schedule.isEmpty {
            guard initialResponse.schedule.period == nil,
                  initialResponse.mayInferPeriod,
                  let inferredPeriod = actualPeriods.first
            else {
                return initialResponse.schedule
            }
            return initialResponse.schedule.inferringPeriodIfMissing(inferredPeriod)
        }

        // u-SAINT 기본 선택값이 방학/미개설 학기이면 실제 LMS 수강 학기를 먼저,
        // 그다음 응답 학기와 날짜 기반 정규학기를 제한된 횟수만 조회합니다.
        let fallbackPeriods = fallbackPeriods(
            actualPeriods: actualPeriods,
            responsePeriod: initialResponse?.schedule.period
        )
        for fallbackPeriod in fallbackPeriods.prefix(maximumFallbackRequests) {
            let response = try await requestTimetable(for: fallbackPeriod)
            guard let response else { continue }

            if bestSuccessfulSchedule == nil
                || bestSuccessfulSchedule?.period == nil {
                bestSuccessfulSchedule = response.schedule
            }
            if !response.schedule.isEmpty {
                return response.schedule
            }
        }

        return bestSuccessfulSchedule
    }

    private func requestTimetable(
        for period: TimetablePeriod?
    ) async throws -> TimetableResponse? {
        try await LMSCallbackBridge.call(timeout: requestTimeout) { completion in
            guard let requestID = callbackGate.begin() else {
                completion(.failure(LMSServiceError.requestTimedOut))
                return
            }
            let complete: @Sendable (Result<TimetableResponse?, Error>) -> Void = {
                result in
                self.callbackGate.finish(requestID)
                completion(result)
            }

            api.getTimetable(
                year: period?.year,
                semester: period.map { lmsSemester($0.semester) }
            ) { result in
                guard result.success else {
                    Self.debugLog("request failed (explicitPeriod=\(period != nil))")
                    complete(
                        .failure(LMSServiceError.serverMessage(
                            raw: result.errorMessage ?? "",
                            fallback: L10n.Timetable.loadFailed
                        ))
                    )
                    return
                }

                guard let timetable = result.timetable else {
                    Self.debugLog("request succeeded without a timetable")
                    complete(.success(nil))
                    return
                }

                let data = TimetableData(
                    year: timetable.year,
                    semester: timetable.semester,
                    items: timetable.items.map {
                        TimetableCellData(
                            dayOfWeek: $0.dayOfWeek.name,
                            period: $0.period,
                            periodTime: $0.periodTime,
                            subject: $0.subject,
                            professor: $0.professor,
                            time: $0.time,
                            classroom: $0.classroom
                        )
                    }
                )
                let schedule = TimetableSchedule(
                    data: data,
                    fallbackPeriod: period
                )
                guard data.items.isEmpty || !schedule.blocks.isEmpty else {
                    Self.debugLog(
                        "mapping failed (raw=\(data.items.count), mapped=0)"
                    )
                    complete(.failure(LMSServiceError.invalidResponse))
                    return
                }

                Self.debugLog(
                    "request succeeded (raw=\(data.items.count), mapped=\(schedule.blocks.count), period=\(schedule.period != nil))"
                )
                complete(
                    .success(TimetableResponse(
                        schedule: schedule,
                        mayInferPeriod: timetable.year
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                            && timetable.semester
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                    ))
                )
            }
        }
    }

    private func fallbackPeriods(
        actualPeriods: [TimetablePeriod],
        responsePeriod: TimetablePeriod?
    ) -> [TimetablePeriod] {
        var periods = actualPeriods
        periods.append(contentsOf: [responsePeriod].compactMap { $0 })
        periods.append(contentsOf: calendarFallbackPeriods())
        var seen = Set<TimetablePeriod>()
        return periods
            .filter { $0.semester == .first || $0.semester == .second }
            .filter { seen.insert($0).inserted }
    }

    private func calendarFallbackPeriods(date: Date = Date()) -> [TimetablePeriod] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        switch month {
        case 8...12:
            return [
                TimetablePeriod(year: String(year), semester: .second),
                TimetablePeriod(year: String(year), semester: .first),
                TimetablePeriod(year: String(year - 1), semester: .second)
            ]
        case 3...7:
            return [
                TimetablePeriod(year: String(year), semester: .first),
                TimetablePeriod(year: String(year - 1), semester: .second)
            ]
        default:
            return [
                TimetablePeriod(year: String(year - 1), semester: .second),
                TimetablePeriod(year: String(year), semester: .first)
            ]
        }
    }

    private func fetchLmsTermPeriods() async throws -> [TimetablePeriod] {
        try await LMSCallbackBridge.call(timeout: .seconds(20)) { completion in
            guard let requestID = callbackGate.begin() else {
                completion(.failure(LMSServiceError.requestTimedOut))
                return
            }
            let complete: @Sendable (Result<[TimetablePeriod], Error>) -> Void = {
                result in
                self.callbackGate.finish(requestID)
                completion(result)
            }

            api.getTerms { result in
                guard result.success else {
                    complete(
                        .failure(LMSServiceError.serverMessage(
                            raw: result.errorMessage ?? "",
                            fallback: L10n.Timetable.loadFailed
                        ))
                    )
                    return
                }

                let periods = result.terms.compactMap { term -> TimetablePeriod? in
                    guard let name = term.name else { return nil }
                    return TimetablePeriod(apiYear: name, apiSemester: name)
                }
                let sortedPeriods = periods.sorted {
                    let lhs = (Int($0.year) ?? 0, $0.semester.sortOrder)
                    let rhs = (Int($1.year) ?? 0, $1.semester.sortOrder)
                    return lhs > rhs
                }
                var seen = Set<String>()
                let uniquePeriods = sortedPeriods.filter { period in
                    seen.insert("\(period.year)-\(period.semester.sortOrder)").inserted
                }
                complete(.success(uniquePeriods))
            }
        }
    }

    private func lmsSemester(_ semester: AcademicSemester) -> Semester {
        switch semester {
        case .first:
            .first
        case .summer:
            .summer
        case .second:
            .second
        case .winter:
            .winter
        }
    }

    private static func debugLog(_ message: @autoclosure () -> String) {
#if DEBUG
        print("[LMS][Timetable] \(message())")
#endif
    }

    private struct TimetableResponse: Sendable {
        let schedule: TimetableSchedule
        let mayInferPeriod: Bool
    }
}

/// Kotlin SDK 요청은 Swift Task timeout으로 취소할 수 없으므로 실제 callback이
/// 도착하기 전에는 다음 SDK 요청이 시작되지 않도록 수명을 추적합니다.
private nonisolated final class TimetableSDKRequestGate: @unchecked Sendable {
    private let lock = NSLock()
    private var activeRequestID: UUID?

    func begin() -> UUID? {
        lock.lock()
        defer { lock.unlock() }

        guard activeRequestID == nil else { return nil }
        let requestID = UUID()
        activeRequestID = requestID
        return requestID
    }

    func finish(_ requestID: UUID) {
        lock.lock()
        defer { lock.unlock() }

        guard activeRequestID == requestID else { return }
        activeRequestID = nil
    }
}
#endif
