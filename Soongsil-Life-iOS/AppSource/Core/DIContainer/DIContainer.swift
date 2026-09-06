import Foundation

struct DIContainer {
    let authenticationRepository: AuthenticationRepositoryProtocol
    let homeRepository: HomeRepositoryProtocol
    let gradeRepository: GradeRepositoryProtocol
    let chapelRepository: ChapelRepositoryProtocol
    let graduationAuditRepository: GraduationAuditRepositoryProtocol
    let timetableService: TimetableServiceProtocol
    let timetableCacheStore: TimetableCacheStoreProtocol
    let timetableCatalogDidChange: () -> Void
    let tuitionRepository: TuitionRepositoryProtocol

    init(
        authenticationRepository: AuthenticationRepositoryProtocol,
        homeRepository: HomeRepositoryProtocol,
        gradeRepository: GradeRepositoryProtocol,
        chapelRepository: ChapelRepositoryProtocol,
        graduationAuditRepository: GraduationAuditRepositoryProtocol,
        timetableService: TimetableServiceProtocol,
        timetableCacheStore: TimetableCacheStoreProtocol,
        timetableCatalogDidChange: @escaping () -> Void,
        tuitionRepository: TuitionRepositoryProtocol
    ) {
        self.authenticationRepository = authenticationRepository
        self.homeRepository = homeRepository
        self.gradeRepository = gradeRepository
        self.chapelRepository = chapelRepository
        self.graduationAuditRepository = graduationAuditRepository
        self.timetableService = timetableService
        self.timetableCacheStore = timetableCacheStore
        self.timetableCatalogDidChange = timetableCatalogDidChange
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
        let chapelCacheStore = FileChapelCacheStore()
        let gradeCacheStore = FileGradeCacheStore()
        let timetableCacheStore = FileTimetableCacheStore()
        let tuitionCacheStore = FileTuitionCacheStore()
        let graduationAuditCacheStore = FileGraduationAuditCacheStore()
        let tuitionRepository = TuitionRepository(
            service: TuitionService(),
            cacheStore: tuitionCacheStore
        )
        let graduationAuditRepository = GraduationAuditRepository(
            service: GraduationAuditService(),
            cacheStore: graduationAuditCacheStore
        )
        let gradeRepository = GradeRepository(
            service: gradeService,
            cacheStore: gradeCacheStore,
            onSummaryChanged: {
                tuitionCacheStore.markStale()
                graduationAuditCacheStore.markStale()
            }
        )

        return DIContainer(
            authenticationRepository: AuthenticationRepository(
                service: authenticationService,
                credentialsStore: KeychainLoginCredentialsStore(),
                activateAccountCache: { studentID in
                    chapelCacheStore.activateAccount(studentID: studentID)
                    gradeCacheStore.activateAccount(studentID: studentID)
                    timetableCacheStore.activateAccount(studentID: studentID)
                    tuitionCacheStore.activate(accountIdentifier: studentID)
                    graduationAuditCacheStore.activate(accountIdentifier: studentID)
                },
                deactivateAccountCache: {
                    chapelCacheStore.deactivateAccount()
                    gradeCacheStore.deactivateAccount()
                    timetableCacheStore.deactivateAccount()
                    tuitionCacheStore.deactivateAndClear()
                    graduationAuditCacheStore.deactivateAndClear()
                }
            ),
            homeRepository: HomeRepository(gradeRepository: gradeRepository),
            gradeRepository: gradeRepository,
            chapelRepository: ChapelRepository(
                service: chapelService,
                cacheStore: chapelCacheStore
            ),
            graduationAuditRepository: graduationAuditRepository,
            timetableService: TimetableService(),
            timetableCacheStore: timetableCacheStore,
            timetableCatalogDidChange: {
                chapelCacheStore.markStale()
                tuitionCacheStore.markStale()
                graduationAuditCacheStore.markStale()
            },
            tuitionRepository: tuitionRepository
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
        let chapelCacheStore = InMemoryChapelCacheStore()
        let gradeCacheStore = InMemoryGradeCacheStore()
        let timetableCacheStore = InMemoryTimetableCacheStore()
        let tuitionCacheStore = InMemoryTuitionCacheStore()
        let graduationAuditCacheStore = InMemoryGraduationAuditCacheStore()
        let cacheAccount = "mock-preview"
        chapelCacheStore.activateAccount(studentID: cacheAccount)
        gradeCacheStore.activateAccount(studentID: cacheAccount)
        timetableCacheStore.activateAccount(studentID: cacheAccount)
        tuitionCacheStore.activate(accountIdentifier: cacheAccount)
        graduationAuditCacheStore.activate(accountIdentifier: cacheAccount)
        let tuitionRepository = TuitionRepository(
            service: MockTuitionService(delay: delay),
            cacheStore: tuitionCacheStore
        )
        let graduationAuditRepository = GraduationAuditRepository(
            service: MockGraduationAuditService(delay: delay),
            cacheStore: graduationAuditCacheStore
        )
        let gradeRepository = GradeRepository(
            service: gradeService,
            cacheStore: gradeCacheStore,
            onSummaryChanged: {
                tuitionCacheStore.markStale()
                graduationAuditCacheStore.markStale()
            }
        )

        return DIContainer(
            authenticationRepository: AuthenticationRepository(
                service: authenticationService,
                credentialsStore: InMemoryLoginCredentialsStore(),
                activateAccountCache: { studentID in
                    chapelCacheStore.activateAccount(studentID: studentID)
                    gradeCacheStore.activateAccount(studentID: studentID)
                    timetableCacheStore.activateAccount(studentID: studentID)
                    tuitionCacheStore.activate(accountIdentifier: studentID)
                    graduationAuditCacheStore.activate(accountIdentifier: studentID)
                },
                deactivateAccountCache: {
                    chapelCacheStore.deactivateAccount()
                    gradeCacheStore.deactivateAccount()
                    timetableCacheStore.deactivateAccount()
                    tuitionCacheStore.deactivateAndClear()
                    graduationAuditCacheStore.deactivateAndClear()
                }
            ),
            homeRepository: HomeRepository(gradeRepository: gradeRepository),
            gradeRepository: gradeRepository,
            chapelRepository: ChapelRepository(
                service: chapelService,
                cacheStore: chapelCacheStore
            ),
            graduationAuditRepository: graduationAuditRepository,
            timetableService: MockTimetableService(delay: delay),
            timetableCacheStore: timetableCacheStore,
            timetableCatalogDidChange: {
                chapelCacheStore.markStale()
                tuitionCacheStore.markStale()
                graduationAuditCacheStore.markStale()
            },
            tuitionRepository: tuitionRepository
        )
    }
}

enum AppConfig {
    static let lmsPackageURL = "https://github.com/chlwhdtn03/LMS-API"
    static let termsURL = URL(
        string: "https://app.notion.com/p/3cf5364b6dbf804eac29dced5d4c9001?source=copy_link"
    )!
    static let privacyURL = URL(
        string: "https://app.notion.com/p/3cf5364b6dbf805a8904f98c452f0cb1?source=copy_link"
    )!
    static let appUpdateConfigurationURL = URL(
        string: "https://raw.githubusercontent.com/yourssu/Soongsil-Life-iOS/main/.github/app-config/ios.json"
    )!
}
