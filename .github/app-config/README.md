# iOS 업데이트 팝업 운영 방법

앱은 `main` 브랜치의 [`ios.json`](./ios.json)을 실행 시점과 앱이 다시 활성화될 때 읽습니다. 이 파일만 GitHub에서 수정하면 App Store에 새 빌드를 올리지 않아도 버전 기준과 팝업 문구가 반영됩니다. GitHub Raw CDN 때문에 반영까지 최대 약 5분이 걸릴 수 있습니다.

## 버전 기준

| 설치 버전 조건 | 동작 |
| --- | --- |
| `설치 버전 < minimumVersion` | 필수 업데이트 |
| major 또는 minor가 `latestVersion`보다 낮음 | 필수 업데이트 |
| patch만 `latestVersion`보다 낮음 | 선택 업데이트 |
| `설치 버전 >= latestVersion` | 표시하지 않음 |

`forceMajorMinorUpdates`를 `false`로 설정하면 major/minor 자동 필수 판정을 끌 수 있습니다. 긴급한 patch도 필수로 올려야 할 때는 `minimumVersion`을 올립니다.

예시:

- `latestVersion: 1.0.1`, `minimumVersion: 1.0.0` → 1.0.0에서 선택 업데이트
- `latestVersion: 1.1.0`, `minimumVersion: 1.1.0` → 모든 1.0.x에서 필수 업데이트
- `latestVersion: 1.0.2`, `minimumVersion: 1.0.2` → 1.0.0과 1.0.1에서 긴급 필수 업데이트

이미 배포된 1.0.0 앱은 major/minor 자동 판정과 `enabled`를 알지 못합니다. 모든 구버전에서도 확실히 필수로 만들려면 반드시 `minimumVersion`을 함께 올려야 합니다.

## 변경 순서

1. 새 버전이 App Store에서 실제로 설치 가능한지 확인합니다.
2. `latestVersion`과 필요 시 `minimumVersion`을 변경합니다.
3. `requiredPrompt`와 `optionalPrompt`의 제목, 본문, 변경점, 버튼 문구를 작성합니다.
4. 문구나 정책을 바꿀 때마다 `revision`을 1씩 올립니다. 같은 실행 중 “다음에 하기”를 누른 사용자에게도 새 안내를 다시 보여줄 때 사용합니다.
5. `main` 브랜치에 병합합니다.

App Store에 아직 보이지 않는 버전으로 `minimumVersion`을 먼저 올리면 사용자가 업데이트할 수 없는 상태로 앱에 갇힐 수 있으므로 금지합니다.

팝업을 긴급히 모두 끄려면 `appStoreURL`을 `null`로 변경합니다. `enabled: false`도 신규 앱에서는 동작하지만 1.0.0 호환을 위해 URL도 함께 비워야 합니다.

기존 최상위 `title`, `message`, `appStoreURL`, `latestVersion`, `minimumVersion` 키는 1.0.0 호환용이므로 삭제하거나 이름을 바꾸지 않습니다. 비밀키나 계정 정보는 이 공개 JSON에 넣지 않습니다.

## Debug와 Preview 테스트

Release 빌드에서는 아래 인자를 모두 무시합니다. Xcode의 Scheme > Run > Arguments에서 필요한 인자 하나만 체크합니다.

- `-appUpdateDisabled`: 팝업 끄기
- `-appUpdateOptional`: 선택 업데이트 팝업
- `-appUpdateRequired`: 필수 업데이트 팝업
- `-appUpdateRemote`: 실제 원격 설정 사용

Simulator와 Preview는 기본적으로 `-appUpdateDisabled`와 같은 상태이며, 실기기 Debug는 기본적으로 원격 설정을 사용합니다.
