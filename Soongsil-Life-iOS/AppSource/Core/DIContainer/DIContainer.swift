import Foundation

struct DIContainer {
    let authenticationRepository: AuthenticationRepositoryProtocol
    let homeRepository: HomeRepositoryProtocol
    let gradeRepository: GradeRepositoryProtocol
    let tuitionRepository: TuitionRepositoryProtocol

    init(
        authenticationRepository: AuthenticationRepositoryProtocol,
        homeRepository: HomeRepositoryProtocol,
        gradeRepository: GradeRepositoryProtocol,
        tuitionRepository: TuitionRepositoryProtocol
    ) {
        self.authenticationRepository = authenticationRepository
        self.homeRepository = homeRepository
        self.gradeRepository = gradeRepository
        self.tuitionRepository = tuitionRepository
    }

    static let mock = makeMockContainer()
    static let preview = makeMockContainer(delayNanoseconds: 0)

    static var app: DIContainer {
        if ProcessInfo.processInfo.arguments.contains("-useMockData") {
            return .mock
        }

        return makeAppContainer()
    }

    private static func makeAppContainer() -> DIContainer {
#if targetEnvironment(simulator)
        makeMockContainer(delayNanoseconds: 0)
#else
        let authenticationService = AuthenticationService()
        let gradeService = GradeService()

        return DIContainer(
            authenticationRepository: AuthenticationRepository(
                service: authenticationService
            ),
            homeRepository: HomeRepository(
                studentService: StudentService(),
                gradeService: gradeService,
                chapelService: ChapelService()
            ),
            gradeRepository: GradeRepository(service: gradeService),
            tuitionRepository: TuitionRepository(service: TuitionService())
        )
#endif
    }

    private static func makeMockContainer(
        isLoggedIn: Bool = true,
        delayNanoseconds: UInt64 = 150_000_000
    ) -> DIContainer {
        let authenticationService = MockAuthenticationService(
            isLoggedIn: isLoggedIn,
            delayNanoseconds: delayNanoseconds
        )
        let gradeService = MockGradeService(
            delayNanoseconds: delayNanoseconds
        )

        return DIContainer(
            authenticationRepository: AuthenticationRepository(
                service: authenticationService
            ),
            homeRepository: HomeRepository(
                studentService: MockStudentService(
                    delayNanoseconds: delayNanoseconds
                ),
                gradeService: gradeService,
                chapelService: MockChapelService(
                    delayNanoseconds: delayNanoseconds
                )
            ),
            gradeRepository: GradeRepository(service: gradeService),
            tuitionRepository: TuitionRepository(
                service: MockTuitionService(delayNanoseconds: delayNanoseconds)
            )
        )
    }
}

enum AppConfig {
    static let lmsPackageURL = "https://github.com/chlwhdtn03/LMS-API"
    static let termsURL = URL(string: "https://scatch.ssu.ac.kr/terms")!
    static let privacyURL = URL(string: "https://scatch.ssu.ac.kr/privacy")!
}
