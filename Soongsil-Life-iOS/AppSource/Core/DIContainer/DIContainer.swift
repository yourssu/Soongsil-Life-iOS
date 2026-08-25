import Foundation

struct DIContainer {
    let authenticationRepository: AuthenticationRepositoryProtocol
    let homeRepository: HomeRepositoryProtocol
    let gradeRepository: GradeRepositoryProtocol
    let chapelRepository: ChapelRepositoryProtocol
    let graduationAuditRepository: GraduationAuditRepositoryProtocol
    let timetableService: TimetableServiceProtocol
    let tuitionRepository: TuitionRepositoryProtocol

    init(
        authenticationRepository: AuthenticationRepositoryProtocol,
        homeRepository: HomeRepositoryProtocol,
        gradeRepository: GradeRepositoryProtocol,
        chapelRepository: ChapelRepositoryProtocol,
        graduationAuditRepository: GraduationAuditRepositoryProtocol,
        timetableService: TimetableServiceProtocol,
        tuitionRepository: TuitionRepositoryProtocol
    ) {
        self.authenticationRepository = authenticationRepository
        self.homeRepository = homeRepository
        self.gradeRepository = gradeRepository
        self.chapelRepository = chapelRepository
        self.graduationAuditRepository = graduationAuditRepository
        self.timetableService = timetableService
        self.tuitionRepository = tuitionRepository
    }

    static let mock = makeMockContainer()
    static let preview = makeMockContainer(delay: .zero)

    static var app: DIContainer {
        if ProcessInfo.processInfo.arguments.contains("-useMockData") {
            return .mock
        }

        return makeAppContainer()
    }

    private static func makeAppContainer() -> DIContainer {
#if targetEnvironment(simulator)
        makeMockContainer(delay: .zero)
#else
        let authenticationService = AuthenticationService()
        let gradeService = GradeService()
        let chapelService = ChapelService()

        return DIContainer(
            authenticationRepository: AuthenticationRepository(
                service: authenticationService,
                credentialsStore: KeychainLoginCredentialsStore()
            ),
            homeRepository: HomeRepository(
                studentService: StudentService(),
                gradeService: gradeService,
                chapelService: chapelService
            ),
            gradeRepository: GradeRepository(service: gradeService),
            chapelRepository: ChapelRepository(service: chapelService),
            graduationAuditRepository: GraduationAuditRepository(
                service: GraduationAuditService()
            ),
            timetableService: TimetableService(),
            tuitionRepository: TuitionRepository(service: TuitionService())
        )
#endif
    }

    private static func makeMockContainer(
        isLoggedIn: Bool = true,
        delay: Duration = .milliseconds(150)
    ) -> DIContainer {
        let authenticationService = MockAuthenticationService(
            isLoggedIn: isLoggedIn,
            delay: delay
        )

        let gradeService = MockGradeService(
            delay: delay
        )
        let chapelService = MockChapelService(delay: delay)

        return DIContainer(
            authenticationRepository: AuthenticationRepository(
                service: authenticationService,
                credentialsStore: InMemoryLoginCredentialsStore()
            ),
            homeRepository: HomeRepository(
                studentService: MockStudentService(
                    delay: delay
                ),
                gradeService: gradeService,
                chapelService: chapelService
            ),
            gradeRepository: GradeRepository(
                service: gradeService
            ),
            chapelRepository: ChapelRepository(service: chapelService),
            graduationAuditRepository: GraduationAuditRepository(
                service: MockGraduationAuditService(
                    delay: delay
                )
            ),
            timetableService: MockTimetableService(delay: delay),
            tuitionRepository: TuitionRepository(
                service: MockTuitionService(
                    delay: delay
                )
            )
        )
    }
}

enum AppConfig {
    static let lmsPackageURL = "https://github.com/chlwhdtn03/LMS-API"
    static let termsURL = URL(string: "https://scatch.ssu.ac.kr/terms")!
    static let privacyURL = URL(string: "https://scatch.ssu.ac.kr/privacy")!
    static let appUpdateConfigurationURL = URL(
        string: "https://raw.githubusercontent.com/yourssu/Soongsil-Life-iOS/main/.github/app-config/ios.json"
    )!
}
