# Soongsil Life iOS

`Soongsil Life iOS`는 숭실대학교 학사 정보를 한곳에서 확인하기 위한 SwiftUI 프로젝트입니다.

- iOS 17+
- SwiftUI + Observation(`@Observable`)
- MVVM Input/Output
- LMS-API 1.6.6.2 (`014b325` revision)
- 한국어 현지화

## Git Flow 및 브랜치 규칙

### 상시 브랜치

| 브랜치 | 역할 |
| --- | --- |
| `main` | 실제 배포 버전만 유지합니다. 직접 작업하거나 푸시하지 않습니다. |
| `dev` | 다음 배포에 포함할 변경 사항을 통합합니다. 모든 작업 브랜치의 기준이자 병합 대상입니다. |

### 작업 브랜치

- 작업 브랜치는 최신 `dev`에서 생성합니다.
- 브랜치 이름은 `{Prefix}/#{이슈번호}` 형식을 사용합니다.
  예: `Feat/#153`, `Fix/#204`, `Design/#87`
- Prefix는 PR 템플릿에 정의된 `Add`, `Chore`, `Comment`, `Del`,
  `Design`, `Docs`, `Feat`, `Fix`, `Merge`, `Refactor`, `Remove`,
  `Setting`, `Test` 중 하나를 사용합니다.
- 하나의 브랜치에서는 하나의 이슈만 작업합니다.
- PR의 base 브랜치는 `dev`로 지정합니다.
- 리뷰와 검증을 마쳐 `dev`에 병합한 작업 브랜치는 원격과 로컬에서
  모두 삭제합니다.
- `#`가 포함된 브랜치 이름을 터미널에서 사용할 때는
  `git switch -c 'Feat/#153'`처럼 따옴표로 감쌉니다.

### Release

- 배포할 때 최신 `dev`에서 `release/{배포버전}` 브랜치를 생성합니다.
  예: `release/1.2.0`
- release 브랜치에서는 배포 전 QA와 버그 수정만 진행합니다.
- 배포 준비가 끝나면 release 브랜치를 `main`과 `dev`에 각각
  병합하고, `main`을 기준으로 배포합니다.
- 배포 커밋에는 `v{배포버전}` 형식의 태그를 생성하고 GitHub Release에
  변경 사항을 기록합니다. 예: `v1.2.0`
- `release/*` 브랜치는 삭제하지 않고 태그 및 GitHub Release와 함께
  배포 이력으로 유지합니다.

## 프로젝트 구조

```text
Soongsil-Life-iOS/AppSource
├── App                         앱 진입점, 로그인/메인 화면 전환
├── Core/DIContainer            실제/Mock 의존성 조립
├── Common
│   ├── DesignSystem            기존 컬러 에셋의 의미 기반 래퍼
│   ├── Protocols               BaseViewModel
│   └── UIComponents            공통 카드, 탭 바, 차트
├── API
│   ├── Authentication          로그인/로그아웃 Service와 Mock
│   ├── Student                 학생 정보 Service와 Mock
│   ├── Grade                   학기/과목 성적 Service와 Mock
│   ├── Chapel                  채플 좌석/출결 Service와 Mock
│   ├── Error                   API 공통 오류
│   └── Mock                    공통 Preview fixture
├── Repository
│   ├── Authentication          인증 Repository
│   ├── Grade                   성적 Repository
│   └── Home                    홈에 필요한 도메인 조립
├── Model                       앱에서 사용하는 도메인 모델
├── Module/<Feature>
│   ├── ViewModels              Input/Output ViewModel
│   └── Views                   SwiftUI View와 Preview
└── Resource/Localization       L10n과 언어별 Localizable.strings
```

이후 문서의 `API/...`, `Module/...`, `Repository/...` 경로는
`Soongsil-Life-iOS/AppSource`를 기준으로 합니다.

화면은 `Module/Login`, `Home`, `Semester`, `Chapel`, `Notification`,
`Setting`, `MainTab`, `Timetable`, `GraduationAudit`, `Tuition`처럼
기능 단위로 나눕니다. 화면 상태를 Reducer에 두지 않으며, ViewModel의
`Output`만 View가 렌더링합니다.

## 홈, 탭과 후속 작업용 빈 화면

메인 탭은 디자인 문서에 맞춰 `홈 / 시간표 / 알림 / 마이` 순서입니다.
채플은 별도 탭이 아니라 홈의 좌석 및 출석 카드에서 상세 화면으로
진입합니다. 홈의 `바로가기`에는 졸업사정표와 등록금·장학금 화면을
연결했습니다.

다음 네 화면은 다른 작업자가 바로 이어서 구현할 수 있도록 배경,
내비게이션 제목, `TODO`, `#Preview`만 둔 상태입니다.

```text
Module/Timetable/Views/TimetableView.swift
Module/Notification/Views/NotificationView.swift
Module/GraduationAudit/Views/GraduationAuditView.swift
Module/Tuition/Views/TuitionView.swift
```

LMS-API 1.6.6.2에는 후속 구현에 사용할 수 있는 API가 이미 있습니다.

- 시간표: `LmsApi.getTimetable`
- 졸업사정표: `LmsApi.getGraduateTable`
- 등록금: `LmsApi.getTuitionTable`
- 장학금: `LmsApi.getScholarshipHistoryTable`

화면에서 `LmsApi.shared`를 직접 호출하지 말고, 기존 흐름대로
해당 도메인의 `ServiceProtocol` → `RepositoryProtocol` → ViewModel의
`Input / Output / transform` 순서로 추가합니다. 예를 들어 시간표는
`TimetableServiceProtocol`과 `TimetableRepositoryProtocol`을 별도
폴더에 추가합니다. 실제 타입에는 `Live` 접미사를 붙이지 않고 Preview
및 테스트 대역에만 `Mock`을 붙입니다.

## ViewModel 규칙

모든 ViewModel은 `BaseViewModel`을 채택하고 같은 형태로 작성합니다.

```swift
@MainActor
protocol BaseViewModel: AnyObject {
    associatedtype Input
    associatedtype Output

    var output: Output { get }

    @discardableResult
    func transform(input: Input) async -> Output
}
```

- 사용자 동작과 생명주기 이벤트는 `Input` case로 전달합니다.
- 화면에 필요한 상태는 `Output`에만 둡니다.
- View에서는 `Task { await viewModel.transform(input: ...) }` 형태로
  이벤트를 보냅니다.
- ViewModel은 구체 타입이 아닌 필요한 도메인의 Repository Protocol만
  생성자로 주입받습니다.
- 실제 구현에는 별도의 `Live` 접미사를 붙이지 않고, 대역에만 `Mock`
  접두사를 붙입니다.

의존성 흐름은 다음과 같습니다.

```text
View
  → ViewModel.transform(input:)
  → <Domain>RepositoryProtocol
  → <Domain>Repository
  → <Domain>ServiceProtocol
  ├── <Domain>Service       실제 LMS-API
  └── Mock<Domain>Service   Preview/Mock 데이터
```

`DIContainer`는 이 객체들을 조립하는 Composition Root입니다. 새로운
기능도 Service Protocol → Repository Protocol → ViewModel 순서로
의존성을 연결합니다.

현재 화면별 주입 경계는 다음과 같습니다.

| 화면/ViewModel | 주입받는 Repository | 사용하는 Service |
| --- | --- | --- |
| AppFlow, Login, Setting | `AuthenticationRepositoryProtocol` | Authentication |
| Home | `HomeRepositoryProtocol` | Student + Grade + Chapel |
| Semester | `GradeRepositoryProtocol` | Grade |

`HomeRepository`만 여러 도메인의 결과를 모아 `Dashboard`를 만듭니다.
학생 정보나 성적 조회가 실패하면 홈 로딩을 실패 처리하고, 채플만
실패했을 때는 나머지 홈을 유지한 채 채플 오류를 별도로 보존합니다.

## 실제 서버와 Mock 전환

실제 서버 연결은
[`chlwhdtn03/LMS-API`](https://github.com/chlwhdtn03/LMS-API)의
`LmsApi.shared`를 각 도메인 Service가 감싸는 방식입니다. 모든 실제
Service가 같은 `LmsApi.shared`를 사용하므로 로그인 세션, 쿠키와
패키지 내부 캐시가 공유됩니다. 앱에 별도의 REST Base URL은 없습니다.

일반 실행에서는 다음 구성이 사용됩니다.

```swift
AuthenticationRepository(service: AuthenticationService())
GradeRepository(service: GradeService())
HomeRepository(
    studentService: StudentService(),
    gradeService: GradeService(),
    chapelService: ChapelService()
)
```

Mock으로 앱 전체를 실행하려면 Xcode에서
**Product → Scheme → Edit Scheme → Run → Arguments Passed On Launch**에
아래 인자를 추가합니다.

```text
-useMockData
```

이 경우 `DIContainer.app`이 `MockAuthenticationService`,
`MockStudentService`, `MockGradeService`, `MockChapelService`를
사용하는 저장소들을 주입합니다. 공통 Mock 응답은
`API/Mock/MockLMSFixtures.swift`에서 관리합니다.

알림 탭은 Mock과 데이터 계층 없이 빈 화면으로 남겨 두었습니다.
알림 요구사항과 서버 API가 정해지면 다른 기능과 동일하게
Service Protocol → Repository Protocol → ViewModel 순서로 추가합니다.

LMS-API 버전은 Xcode의 Package Dependencies와 `Package.resolved`에서
관리합니다. 현재 최신 릴리스 `1.6.6.2`는 SwiftPM이 버전으로 인식하지
못하는 네 구간 태그이므로, 같은 릴리스 커밋 `014b325`를 revision으로
고정합니다.

## LMS-API 1.6.6.2와 실행 대상

LMS-API 1.6.6.2의 바이너리는 `ios-arm64` 실기기 슬라이스만 제공합니다.
따라서 스킴을 용도별로 분리했습니다.

| 스킴 | 실행 대상 | 실제 도메인 Service | 용도 |
| --- | --- | --- | --- |
| `Soongsil-Life-iOS` | 실제 iPhone/iPad | 포함 | 로그인과 실제 LMS API 확인 |
| `Soongsil-Life-iOS-Preview` | iOS Simulator | 제외 | SwiftUI Canvas와 Mock UI 확인 |

메인 타깃은 Xcode Build Settings에서 실제 기기용으로 제한합니다.
Preview 타깃은 `LmsApi` 패키지에 링크하지 않고
아래 실제 구현 파일을 타깃에서 제외하며, 지연 시간이 없는 Mock을
자동 사용합니다.

```text
Soongsil-Life-iOS/AppSource/API/Authentication/AuthenticationService.swift
Soongsil-Life-iOS/AppSource/API/Student/StudentService.swift
Soongsil-Life-iOS/AppSource/API/Grade/GradeService.swift
Soongsil-Life-iOS/AppSource/API/Chapel/ChapelService.swift
```

SwiftUI Preview를 볼 때는 상단 스킴을
`Soongsil-Life-iOS-Preview`로 바꾸고 Simulator를 선택합니다. Preview
타깃에 `LmsApi`를 다시 추가하면 바이너리의 Simulator 슬라이스가 없어
Canvas가 빌드되지 않습니다.

## 기존 컬러와 아이콘 에셋

기존 컬러와 SVG 아이콘은 삭제하지 않았습니다. 아래 원래 리소스 경로를
Xcode 프로젝트의 File System Synchronized Group으로 연결해 메인 타깃과
Preview 타깃이 함께 사용합니다.

```text
Soongsil-Life-iOS/Soongsil-Life-iOS/Resource/Assets Catalog
├── Assets.xcassets
│   ├── AppIcon
│   ├── AccentColor
│   └── Icon
│       ├── ic_home
│       ├── ic_sofa
│       ├── ic_bell
│       ├── ic_person
│       ├── ic_info
│       ├── ic_qr
│       ├── ic_calender
│       └── ic_alarm_setting
└── Color.xcassets
    ├── blue_25 ... blue_600
    ├── gray_25 ... gray_950
    ├── slate_100 ... slate_600
    ├── navy_700 ... navy_900
    └── green, orange, red, black, white, background
```

아이콘은 `Image("ic_home")`처럼 기존 이름을 그대로 사용합니다. 컬러는
`SoomsilDesignSystem.swift`에서 `Color("blue_600")` 같은 원본 에셋을
`soomsilBlue600`, `soomsilBackground`, `soomsilPrimaryText` 등으로
래핑합니다. 에셋을 `Soongsil-Life-iOS/AppSource` 안에 중복 복사하면
같은 이름의 리소스가
두 번 포함될 수 있으므로 기존 카탈로그를 단일 원본으로 유지합니다.

## Localization

사용자에게 보이는 문구는 View에 직접 쓰지 않고 `L10n`을 통해
접근합니다. 현재 지원 언어와 기본 언어는 한국어입니다.

```text
Soongsil-Life-iOS/AppSource/Resource/Localization
├── L10n.swift
└── ko.lproj/Localizable.strings
```

문구를 추가할 때는 다음 순서를 지킵니다.

1. `ko.lproj/Localizable.strings`에 키와 한국어 문구를 추가합니다.
2. 포맷 문자열의 `%@`, `%d` 타입과 개수를 호출부와 맞춥니다.
3. `L10n.swift`의 알맞은 그룹에 접근 프로퍼티 또는 포맷 함수를
   추가합니다.
4. View에서는 `Text(L10n.Home.loading)`처럼 접근합니다.

나중에 다국어를 지원하려면 한국어와 같은 키를 가진
`<언어코드>.lproj/Localizable.strings` 파일을 추가하고 Xcode 프로젝트의
Localizations에도 언어를 등록합니다.

## 처음 실행하기

1. `Soongsil-Life-iOS/Soongsil-Life-iOS.xcodeproj`를 엽니다.
2. Xcode가 LMS-API 1.6.6.2를 Resolve할 때까지 기다립니다.
3. 실제 API를 확인할 때는 `Soongsil-Life-iOS` 스킴과 실제 iPhone/iPad를
   선택합니다.
4. **Signing & Capabilities**에서 본인의 Team을 선택합니다.
5. UI와 Preview를 확인할 때는 `Soongsil-Life-iOS-Preview` 스킴과
   Simulator를 선택합니다.

## `No such module 'LmsApi'`

패키지 저장소 이름은 `LMS-API`지만 Swift 모듈 이름은 대소문자를
구분하는 `LmsApi`입니다. 메인 타깃에서 오류가 나면 다음을 확인합니다.

1. Xcode의 **Project → Package Dependencies**에
   `https://github.com/chlwhdtn03/LMS-API` 1.6.6.2가 있는지 확인합니다.
2. 메인 타깃 **General → Frameworks, Libraries, and Embedded Content**에
   `LmsApi`가 연결됐는지 확인합니다.
3. **File → Packages → Reset Package Caches**를 실행한 뒤
   **Resolve Package Versions**를 실행합니다.
4. **Product → Clean Build Folder** 후 다시 빌드합니다.
5. 메인 스킴이라면 Simulator가 아니라 실제 기기를 선택합니다.

Simulator 또는 Canvas에서 같은 오류가 나면 실제 모듈을 연결하려고 한
것입니다. `Soongsil-Life-iOS-Preview` 스킴을 선택해야 하며, 이 타깃에는
의도적으로 `LmsApi`가 없습니다.

## Apple PLA와 Provisioning 오류

다음 두 오류는 앱 코드나 LMS-API 문제가 아니라 Apple Developer 계정의
서명 설정 문제입니다.

```text
PLA Update available
No profiles for 'com.soongsillife.ios' were found
```

`PLA Update available`은 Team의 Account Holder가 Apple Developer
계정에서 최신 Program License Agreement에 동의해야 해결됩니다. 동의가
끝난 뒤 Xcode **Settings → Accounts**에서 계정을 다시 갱신합니다.

Provisioning Profile 오류는 다음 순서로 해결합니다.

1. Xcode **Signing & Capabilities**에서 올바른 Team을 선택합니다.
2. **Automatically manage signing**을 켭니다.
3. 현재 Team에서 사용할 수 있는 고유한 Bundle Identifier인지
   확인합니다.
4. Bundle ID를 바꿔야 하면 앱 타깃의 **Signing & Capabilities**에서
   수정합니다.

PLA 동의가 처리되지 않은 상태에서는 Xcode가 새로운 App ID나
Provisioning Profile을 만들 수 없으므로, 반드시 PLA 문제를 먼저
해결해야 합니다. 서명 없이 하는 로컬 빌드 검증은 가능하지만 실제
기기 설치와 배포는 유효한 Team 및 Profile이 필요합니다.
