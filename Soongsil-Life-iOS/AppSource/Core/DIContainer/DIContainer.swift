import Foundation

struct DIContainer {
    let authenticationRepository: AuthenticationRepositoryProtocol
    let homeRepository: HomeRepositoryProtocol
    let gradeRepository: GradeRepositoryProtocol
    let notificationRepository: NotificationRepositoryProtocol //추가

    init(
        authenticationRepository: AuthenticationRepositoryProtocol,
        homeRepository: HomeRepositoryProtocol,
        gradeRepository: GradeRepositoryProtocol,
        notificationRepository: NotificationRepositoryProtocol //추가
    ) {
        self.authenticationRepository = authenticationRepository
        self.homeRepository = homeRepository
        self.gradeRepository = gradeRepository
        self.notificationRepository = notificationRepository //추가
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
            //추가
            notificationRepository: NotificationRepository(
                            service: NotificationService()
            )
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
            //추가
            notificationRepository: NotificationRepository(
                            service: MockNotificationService(
                                delayNanoseconds: delayNanoseconds
                            )
                        )
        )
    }
}

enum AppConfig {
    static let lmsPackageURL = "https://github.com/chlwhdtn03/LMS-API"
    static let termsURL = URL(string: "https://scatch.ssu.ac.kr/terms")!
    static let privacyURL = URL(string: "https://scatch.ssu.ac.kr/privacy")!
}
