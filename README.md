# Soongsil Life iOS

`Soongsil Life iOS`는 데스크톱 중심의 숭실대학교 학사 시스템 정보를
iPhone에서 한곳에 모아 확인할 수 있도록 만든 SwiftUI 앱입니다. 숭실대학교가
직접 제공하는 공식 앱은 아니며, 중요한 학사 판단 전에는 u-SAINT 등 학교 공식
시스템의 정보를 다시 확인해야 합니다.

- iOS 17 이상, iPhone 세로 화면
- SwiftUI + Observation(`@Observable`)
- MVVM Input/Output + 생성자 기반 의존성 주입
- 홈 / 채플 / 시간표 / 마이 탭
- Keychain 기반 자동 로그인과 세션 복원
- 로딩·빈 데이터·오류·재시도 상태 분리
- 한국어 현지화

## 주요 기능

- **홈**: 학생 정보와 누적·학기 성적을 먼저 표시하고, 채플 요약은 독립된
  로딩·수강·수료·미수강·오류 상태로 갱신합니다. 학기별 성적, 졸업사정표,
  등록금·장학금 화면으로 이동할 수 있습니다.
- **채플**: 현재 수강 중이면 좌석, 장소, 출결 요약과 상세 출결을 표시합니다.
  현재 수강 정보가 없으면 과거 이수 횟수에 따라 수료 완료와 미수강을 구분합니다.
- **시간표**: LMS가 반환한 학기를 최신순으로 선택하고 수업 블록과 과목 상세를
  표시합니다. 시간이 정해진 수업이 없는 학기도 정상적인 빈 상태로 처리합니다.
- **마이**: 로그아웃, 이용약관, 개인정보 처리방침, 오픈소스 라이선스와 앱 버전을
  제공합니다. 알림 기능과 알림 설정은 현재 출시 범위에 포함하지 않습니다.
- **졸업사정표**: 졸업 요건을 분류별로 묶고 서버의 `충족` / `부족` 상태와
  사용 과목을 표시합니다.
- **등록금·장학금**: 등록금과 장학금 이력을 탭으로 구분해 최신 학기부터
  표시합니다.
- **앱 업데이트**: 원격 버전 정책에 따라 선택 또는 필수 업데이트 안내를
  표시하되, 설정 조회나 App Store 열기에 실패해도 앱 진입을 막지 않습니다.

## 프로젝트 구조

```text
.
├── LocalPackages/LmsApi               앱 저장소 안의 iOS 클라이언트 패키지 래퍼
├── Soongsil-Life-iOS
│   ├── AppSource
│   │   ├── App                         앱 진입점과 세션 복원
│   │   ├── Core
│   │   │   ├── DIContainer             실제/Mock 의존성 조립
│   │   │   └── Security                Keychain 로그인 정보 저장소
│   │   ├── Common
│   │   │   ├── Concurrency             중복 비동기 작업 방지
│   │   │   ├── DesignSystem            의미 기반 색상 래퍼
│   │   │   ├── Formatters              통화 등 공통 포맷
│   │   │   ├── MockSupport             취소 가능한 Mock 지연
│   │   │   ├── Navigation              공통 상세 내비게이션
│   │   │   ├── Protocols               BaseViewModel
│   │   │   └── UIComponents            공통 카드, 탭 바와 차트
│   │   ├── API
│   │   │   ├── Service                 callback/async 브리지와 timeout
│   │   │   ├── Authentication          로그인과 로그아웃
│   │   │   ├── Student                 학생 정보
│   │   │   ├── Grade                   학기와 과목 성적
│   │   │   ├── Chapel                  채플 좌석·출결과 이수 상태
│   │   │   ├── Timetable               시간표와 학기 목록
│   │   │   ├── GraduationAudit         졸업사정표
│   │   │   ├── Tuition                 등록금과 장학금
│   │   │   ├── AppUpdate               원격 버전 정책
│   │   │   ├── Error                   공통 LMS 오류
│   │   │   └── Mock                    공통 Preview fixture
│   │   ├── Repository
│   │   │   ├── Authentication          인증과 자격 증명 저장 조율
│   │   │   ├── Grade                   성적 도메인 변환
│   │   │   ├── Chapel                  채플 도메인 경계
│   │   │   ├── GraduationAudit         졸업사정표 도메인 경계
│   │   │   ├── Tuition                 등록금·장학금 정렬
│   │   │   └── Home                    학생·성적 기본 Dashboard 조립
│   │   ├── Model                       화면과 도메인 모델
│   │   ├── Module                      기능별 ViewModel과 SwiftUI View, MainTab 상태 소유
│   │   └── Resource
│   │       ├── Licenses                오픈소스 라이선스
│   │       ├── Localization            L10n과 한국어 문자열
│   │       └── PrivacyInfo.xcprivacy   개인정보 매니페스트
│   └── Soongsil-Life-iOS.xcodeproj
├── TERMS.md                            외부 공개용 이용약관
└── PRIVACY.md                          외부 공개용 개인정보 처리방침
```

이후 문서의 `API/...`, `Module/...`, `Repository/...` 경로는
`Soongsil-Life-iOS/AppSource`를 기준으로 합니다. 시간표는 불필요한 전달
계층을 두지 않고 `TimetableServiceProtocol`을 ViewModel에 직접 주입하므로
`Repository/Timetable` 경로는 존재하지 않습니다.

## 아키텍처와 책임

모든 화면 ViewModel은 `BaseViewModel`의 Input/Output 형태를 따릅니다.

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

- View는 사용자 동작과 생명주기 이벤트를 `Input`으로 전달하고 `Output`만
  렌더링합니다.
- ViewModel은 로딩, 성공, 빈 데이터와 오류 상태를 관리하며 구체 구현 대신
  필요한 Protocol을 생성자로 주입받습니다.
- Repository는 도메인 변환, 정렬 또는 여러 Service 결과 조합이 필요할 때만
  둡니다.
- Service는 `LmsApi.shared` callback을 async 함수로 감싸고 SDK 응답을 앱
  모델로 변환합니다.
- `DIContainer`는 실제와 Mock 구현을 조립하는 Composition Root입니다.
- `MainTabView`는 `HomeViewModel`과 하나의 `ChapelViewModel` 생명주기를
  소유합니다. 같은 `ChapelViewModel`을 홈의 채플 카드와 채플 탭에 전달해
  상태와 중복 요청 방지를 공유합니다.

```text
View
  → ViewModel.transform(input:)
  → RepositoryProtocol         필요한 기능만 사용
  → ServiceProtocol
  → LmsApi.shared 또는 Mock Service
```

현재 주입 경계는 다음과 같습니다.

| 화면/ViewModel | 주입받는 Protocol | 실제 데이터 원천 |
| --- | --- | --- |
| AppFlow, Login, Setting | `AuthenticationRepositoryProtocol` | Authentication Service |
| Home / `HomeViewModel` | `HomeRepositoryProtocol` | Student + Grade Service |
| Semester | `GradeRepositoryProtocol` | Grade Service |
| Home 채플 카드 + Chapel / 공유 `ChapelViewModel` | `ChapelRepositoryProtocol` | Chapel Service |
| Timetable | `TimetableServiceProtocol` | Timetable Service |
| GraduationAudit | `GraduationAuditRepositoryProtocol` | GraduationAudit Service |
| Tuition | `TuitionRepositoryProtocol` | Tuition Service |
| AppUpdate | `AppUpdateServiceProtocol` | GitHub의 앱 버전 정책 JSON |

## 비동기 요청과 오류 처리

`LMSCallbackBridge`는 Kotlin/Native SDK callback을 Swift async 함수로
변환합니다. 기본 timeout은 20초이며 로그인은 30초, 로그아웃은 5초,
시간표는 45초, 졸업사정표와 채플 이수 횟수 조회는 60초를 사용합니다.
취소, timeout과 실제 callback이 경쟁해도 continuation은 한 번만 완료됩니다.

`AsyncSingleFlight`는 같은 ViewModel의 중복 로드 요청을 하나로 합칩니다. 인증과
시간표는 Swift Task가 timeout된 뒤에도 취소할 수 없는 SDK 요청이 남을 수
있으므로 별도 gate가 실제 callback 전까지 다음 SDK 요청 시작을 막습니다.
화면에는 SDK 원문 대신 네트워크 단절, timeout과 기능별 fallback 문구를
표시합니다.

각 기능의 상태 기준은 다음과 같습니다.

홈 진입 시 `HomeViewModel`과 공유 `ChapelViewModel`의 요청은 독립적으로
시작됩니다. `HomeRepository`는 Student·Grade Service 결과만 조합하므로 채플
조회나 최대 60초의 이수 횟수 fallback을 기다리지 않고 기본 Dashboard를 먼저
표시합니다. 이후 채플 카드만 공유 ViewModel의 상태에 따라 갱신되며, 채플
탭으로 이동해도 같은 결과와 진행 중인 요청을 이어서 사용합니다.

| 기능 | 성공 | 빈 데이터 | 실패 |
| --- | --- | --- | --- |
| 홈 | Student·Grade 조회가 끝나면 프로필·성적·바로가기를 먼저 표시하고, 채플 카드는 `idle` / `loading` 뒤 `loaded` 상태의 좌석·출결을 표시 | 최신 학기나 과목이 없으면 빈 목록으로 표시하고, 채플 `notEnrolled`는 이수 6회 이상이면 수료 완료, 6회 미만이면 현재 미수강으로 표시 | 학생·성적 실패는 홈 전체 오류, 채플 `failed`는 나머지 홈을 유지하고 채플 카드만 오류·독립 재시도 |
| 채플 | 홈과 공유하는 `ChapelViewModel`의 `loaded` 상태로 좌석·출결을 표시 | 현재 수강 정보가 없거나 알려진 채플 서비스 중단 응답이면 졸업사정표의 이수 횟수를 조회해 6회 이상은 수료 완료, 6회 미만은 현재 미수강으로 표시 | 실제 네트워크 오류 또는 이수 횟수 대체 조회 실패는 홈 채플 카드와 채플 탭에 같은 재시도 상태로 표시 |
| 시간표 | 선택한 학기의 시간이 있는 수업을 그리드로 표시하고 결과를 캐시 | 정상 조회 결과에 배치할 수업이 없으면 현장실습·온라인 수업 등이 가능한 정상 빈 상태로 표시 | 전송·인증·timeout·파싱 실패는 오류로 표시하고, 이전 그리드가 있으면 유지 |
| 졸업사정표 | 비어 있지 않은 표의 모든 행이 정확히 `충족` 또는 `부족`일 때 표시 | 실제 Service는 빈 표를 정상 결과로 위장하지 않고 잘못된 응답으로 처리 | 표 누락, 빈 표, 알 수 없는 상태 또는 파싱 실패는 재시도 오류 |
| 등록금·장학금 | 두 요청을 `async let`으로 동시에 시작하고 둘 다 성공해야 새 결과를 함께 반영 | 성공한 배열이 비어 있으면 해당 탭에 내역 없음 문구를 표시 | 어느 한 요청이라도 실패하면 그 로드 시도는 오류이며, 기존 데이터가 있으면 유지한 채 알림을 표시하고 첫 로드라면 재시도 화면 표시 |

## 자동 로그인과 자격 증명

로그인 성공 후 `AuthenticationRepository`가 학번과 비밀번호를
`KeychainLoginCredentialsStore`에 저장합니다. Keychain 항목은
`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`로 설정되어 잠금 해제된 해당
기기에서만 접근할 수 있습니다. `UserDefaults`에는 자격 증명이 아니라 자동
로그인 활성화 여부만 기록합니다.

앱을 다시 실행하면 저장된 자격 증명으로 세션 복원을 시도합니다. 복원 실패
화면에서는 다시 시도하거나 다른 계정으로 전환할 수 있습니다. 로그아웃은 LMS
세션 종료가 성공한 뒤에만 자동 로그인 표시를 끄고 Keychain 항목을 삭제합니다.
SDK 로그아웃이 실패하면 세션과 자격 증명을 유지한 채 재시도를 안내합니다.
Keychain 저장이 실패해도 이미 성공한 수동 로그인 세션은 유지합니다.

## 로컬 LmsApi 패키지

실제 서버 연결은
[`chlwhdtn03/LMS-API`](https://github.com/chlwhdtn03/LMS-API/tree/014b325fea9bcd234a21edaf0f8e41b0debadcba)의
`LmsApi.shared`를 사용합니다. 이 앱은 서버를 포함하거나 대체하지 않으며 별도
REST Base URL도 두지 않습니다.

Xcode 프로젝트는 원격 패키지를 직접 가져오는 대신
[`LocalPackages/LmsApi`](LocalPackages/LmsApi/README.md)를 로컬 Swift
Package로 참조합니다. 이 패키지는 upstream revision
`014b325fea9bcd234a21edaf0f8e41b0debadcba`에서 빌드한 iOS 클라이언트
바이너리를 앱 저장소 안에서 감싸는 래퍼입니다.

로컬 클라이언트의 보완 범위는 다음으로 제한됩니다.

- 큰 단일 행 Web Dynpro HTML을 재귀 정규식 대신 선형으로 탐색
- 선택 과목 상세 동작을 사용할 수 없을 때 기본 졸업사정표 유지
- 선택 과목 열 유무와 관계없이 서버의 `충족` / `부족` 계약 유지

공식 LMS-API 저장소 자체는 수정하지 않았습니다. 로컬 패키지에는 서버,
실계정 자격 증명, 코드사인 설정, 인증서 또는 provisioning asset이 없습니다.
라이선스 전문은
[`LMS-API-LICENSE.txt`](Soongsil-Life-iOS/AppSource/Resource/Licenses/LMS-API-LICENSE.txt)에서
확인할 수 있습니다.

## 실제 서버와 Mock

실제 앱은 각 Service가 같은 `LmsApi.shared`를 사용하므로 로그인 세션, 쿠키와
SDK 내부 캐시를 공유합니다. Xcode에서 메인 `Soongsil-Life-iOS` 스킴과 실제
iPhone을 선택하면 실제 학사 시스템을 조회합니다.

앱 전체를 Mock 데이터로 실행하려면 Xcode의 **Product → Scheme → Edit
Scheme → Run → Arguments Passed On Launch**에 다음 인자를 추가합니다.

```text
-useMockData
```

이 경우 `DIContainer.app`이 Authentication, Student, Grade, Chapel,
Timetable, GraduationAudit, Tuition의 Mock 구현을 주입합니다. 공통 fixture는
`API/Mock/MockLMSFixtures.swift`에서 관리합니다.

`Soongsil-Life-iOS-Preview` 스킴은 Simulator와 SwiftUI Canvas용입니다.
Preview 타깃은 `PREVIEW_TARGET` 조건으로 실제 LMS 구현을 제외하고 지연 없는
Mock 조합을 사용합니다. 로컬 `LmsApi.xcframework`는 `ios-arm64` 실기기
슬라이스만 제공하므로 Simulator에서 실제 LMS 모듈을 연결하지 않습니다.

## 앱 업데이트 정책

앱 실행 시 `AppUpdateService`가
[`ios.json`](.github/app-config/ios.json)을 5초 timeout으로 조회합니다.
현재 버전이 `minimumVersion`보다 낮으면 필수, `latestVersion`보다 낮으면 선택
업데이트 안내를 표시합니다. App Store URL은 HTTPS이며 `apps.apple.com` 또는
`itunes.apple.com` 도메인일 때만 사용합니다.

원격 설정 조회, JSON 파싱 또는 App Store 열기에 실패하면 fail-open으로 안내를
닫고 앱 사용을 허용합니다. `appStoreURL`이 비어 있는 동안에는 버전 숫자와
관계없이 업데이트 화면을 표시하지 않습니다.

## 이용약관과 개인정보

이용약관과 개인정보 처리방침은 로그인 화면과 마이 화면에서 모두 접근할 수
있습니다. 앱 화면용 문서는 `Module/Setting/Models/LegalDocument.swift`, 외부
공개용 문서는 [`TERMS.md`](TERMS.md)와 [`PRIVACY.md`](PRIVACY.md)에서
관리합니다. 처리 정보나 보관 방식이 바뀌면 두 표현을 함께 갱신합니다.

[`PrivacyInfo.xcprivacy`](Soongsil-Life-iOS/AppSource/Resource/PrivacyInfo.xcprivacy)는
앱 타깃의 개인정보 매니페스트입니다. 현재 추적과 수집 데이터 유형은 선언하지
않으며, 앱 전용 설정값을 위한 UserDefaults 접근 사유 `CA92.1`만 선언합니다.

## Localization

사용자에게 보이는 문구는 View에 직접 쓰지 않고 `L10n`을 통해 접근합니다.
현재 지원 언어와 기본 언어는 한국어입니다.

```text
Soongsil-Life-iOS/AppSource/Resource/Localization
├── L10n.swift
└── ko.lproj/Localizable.strings
```

문구를 추가할 때는 다음 순서를 지킵니다.

1. `ko.lproj/Localizable.strings`에 키와 한국어 문구를 추가합니다.
2. 포맷 문자열의 `%@`, `%d` 타입과 개수를 호출부와 맞춥니다.
3. `L10n.swift`의 알맞은 그룹에 접근 프로퍼티 또는 포맷 함수를 추가합니다.
4. View에서는 `Text(L10n.Home.loading)`처럼 접근합니다.

## 처음 실행하기

1. `Soongsil-Life-iOS/Soongsil-Life-iOS.xcodeproj`를 엽니다.
2. Xcode가 `../LocalPackages/LmsApi` 로컬 패키지를 인식했는지 확인합니다.
3. 실제 API는 `Soongsil-Life-iOS` 스킴과 실제 iPhone에서 확인합니다.
4. UI와 Preview는 `Soongsil-Life-iOS-Preview` 스킴과 Simulator에서
   확인합니다.
5. 실기기 설치가 필요할 때만 로컬 Xcode 환경에서 자신의 서명 설정을
   선택합니다.

코드사인 없이 코드와 로컬 패키지 연결을 검증하는 명령은 다음과 같습니다.

```shell
xcodebuild \
  -project Soongsil-Life-iOS/Soongsil-Life-iOS.xcodeproj \
  -scheme Soongsil-Life-iOS \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### `No such module 'LmsApi'`

패키지 저장소 이름은 `LMS-API`지만 Swift 모듈 이름은 대소문자를 구분하는
`LmsApi`입니다. 오류가 나면 다음을 확인합니다.

1. `LocalPackages/LmsApi/Package.swift`와
   `LocalPackages/LmsApi/LmsApi.xcframework/ios-arm64`가 존재하는지 확인합니다.
2. Xcode **Project → Package Dependencies**의 참조가
   `../LocalPackages/LmsApi`인지 확인합니다.
3. 메인 타깃의 **Frameworks, Libraries, and Embedded Content**에 `LmsApi`가
   연결됐는지 확인합니다.
4. **File → Packages → Reset Package Caches**, **Resolve Package Versions**,
   **Product → Clean Build Folder** 순서로 다시 빌드합니다.
5. 실제 LMS 조회라면 Simulator가 아니라 실제 iPhone을 선택합니다. Simulator와
   Canvas에서는 `Soongsil-Life-iOS-Preview` 스킴을 사용합니다.

## 저장소 보안 원칙

- 실제 학번, 비밀번호, 세션 쿠키와 개인 로그를 커밋하지 않습니다.
- 개발자 계정 식별자, Team 설정, 인증서, private key와 provisioning profile을
  저장소에 추가하지 않습니다.
- 로컬 실기기 실행을 위한 서명 변경은 개인 Xcode 환경에만 남깁니다.
- 민감 파일이 이미 추적된 경우 `.gitignore`만 추가하지 말고 Git 이력과 노출
  범위를 별도로 점검합니다.

## Git Flow

| 브랜치 | 역할 |
| --- | --- |
| `main` | 심사와 배포를 마친 버전을 유지합니다. |
| `dev` | 다음 배포에 포함할 변경 사항을 통합합니다. |

- 작업 브랜치는 최신 `dev`에서 `{Prefix}/#{이슈번호}` 형식으로 생성합니다.
  예: `Feat/#153`, `Fix/#204`, `Docs/#29`
- 하나의 브랜치에서는 하나의 이슈만 다루고 PR의 base는 `dev`로 지정합니다.
- 배포 전 QA는 최신 `dev`에서 만든 `release/{배포버전}` 브랜치에서 진행합니다.
- 배포 커밋은 `v{배포버전}` 태그와 GitHub Release로 기록합니다.
