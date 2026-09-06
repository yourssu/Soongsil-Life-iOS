# Soongsil Life iOS UI implementation reference

This file is the local implementation record for the Figma file
`jGjCngiOYICbVqu1S08zKz` (`Untitled`, root node `0:1`). It exists so future
iterations can use the captured measurements and exported references without
spending additional Figma MCP calls.

## Source of truth and constraints

- Figma: `https://www.figma.com/design/jGjCngiOYICbVqu1S08zKz/Untitled?node-id=0-1`
- Design viewport: 390 pt wide iPhone portrait.
- Font: bundled `PretendardVariable.ttf`; use `Font.pretendard`.
- Horizontal insets are screen-specific. Login uses 24 pt, Graduation Audit
  uses 20 pt, Timetable uses 20 pt for its header and 16 pt for its grid, and
  My uses 20 pt for its header and 24 pt for its sections.
- Main foreground: `black000`; background: `white000`.
- Reference blue in the Figma export: `#2272EB` (600) and `#3182F6` (500).
- Splash artwork colors: `#45539B` (`splashIndigo`) and `#7F78FF`
  (`splashViolet`).
- Reference gray values: `#8B95A1` (500), `#D1D6DB` (300),
  `#E5E8EB` (200), `#F8F9FA` (50).
- The app is light-mode only.
- When an older export conflicts with the latest product feedback or the
  behavior contract in code, use the latest feedback and current code.
- Existing repositories, service calls, loading/error/empty states and data
  conversion are behavior contracts and must not be removed for visual work.
- `ChapelSeatMapData` and the A–J seat geometry/aisles are immutable. Only the
  seat map's presentation, color, scaling and surrounding card may change.

## Figma node index

| Screen | Node |
| --- | --- |
| Home variants | `2:227`, `2:468`, `2:709`, `2:950`, `2:1191` |
| Timetable | `2:1432` |
| Timetable course bottom sheet | `2:1528` |
| My | `2:1646` |
| Graduation audit collapsed | `2:1754` |
| Graduation audit expanded | `2:1826` |
| Splash | `2:2035` |
| Login empty | `2:2042` |
| Login filled | `2:2076` |
| Login loading | `2:2110` |
| Required agreements empty | `2:2123` |
| Required agreements checked | `2:2161` |
| Onboarding complete | `2:2207` |
| Semester grades | `2:2243`, `2:2420` |
| Chapel details / seat | `2:2597` |
| Scholarship history | `2:2681` |
| Tuition history | `2:2737` |
| Historical graduation card/detail variants (inactive) | `2:2823`, `2:2996` |
| Grade assets | `2:3009`, `2:3138` |

## Exported local references

The supplied PNG/PDF files under `/Users/jeongminji/Downloads` are the fallback
source of truth when Figma MCP access is limited. Important names:

- Home: `Frame 2147242355`, `2147242477`, `2147242478`, `2147242480`,
  `2147242490`
- Semester: `Frame 2147242356`, `2147242488`, `ssuGrade`, `ListItem`
- Timetable: `Frame 2147242418`, `2147242487`
- My: `Frame 2147242485`, `v3 Android - My Page`
- Chapel: `Frame 2147242362` and the supplied stage/seat screenshot
- Tuition/scholarship: `Frame 2147242359`, `2147242358`
- Graduation audit: `Frame 2147242437`, `2147242484`. The older
  `졸업사정표` export is historical and is not the active UI reference.
- Onboarding: `Frame 2147242402`, `2147242403`, `2147242404`,
  `2147242405`, `2147242406`, `2147242415`

Exact Figma SVG exports stored in the asset catalog:

- `soomsilLogo`
- `loginLoadingIndicator`
- `onboardingCompleteIndicator`
- `ic_home`
- `ic_home_fill`
- `ic_calender`
- `ic_calender_fill`
- `ic_person`
- `ic_person_fill`

The initial session-restore animation is the bundled
`Soongsil-Life-iOS/AppSource/Resource/logoAni.mp4`, not an asset-catalog SVG.
`Frame 2147242365.mp4` is only a full-screen placement reference and must not
replace the bundled animation.

## Authentication and onboarding

### Login (`2:2042`, `2:2076`)

- Logo: 99 × 48 pt, x=24, top near 120.
- Content column: x=24, y=200, width=342.
- Heading: Pretendard Bold 28, 1.4 line height, tracking -0.112;
  `유세인트에\n로그인해주세요`.
- Subtitle: Pretendard Medium 15, gray, 1.4 line height;
  `학사 정보를 한눈에 확인할 수 있어요`.
- Gap from the heading block to fields: 52 pt.
- Text fields: 342 × 52, radius 4, 1 pt gray border, 20 pt horizontal
  padding, 12 pt vertical gap, Medium 16.
- Forgot-password action: trailing aligned with 4 pt inset, Medium 14.
- Primary button: 14 pt horizontal inset, 56 pt height, radius 12, Semibold 18.
  It is installed with a bottom safe-area inset, follows the keyboard, and the
  focused field scrolls into view so the button, keyboard and field do not
  overlap.

### Login loading (`2:2110`)

- Root replacement screen, not an overlay and not a pushed destination.
- `loginLoadingIndicator` is a static 112 × 112 pt SVG; it renders the visible
  blue circle at the intended 96 pt diameter inside its shadow bounds. It is
  not the animated session splash.
- The measured group uses a 39 pt outer gap and a -62 pt vertical offset on a
  390 × 844 viewport.
- Title: Bold 28, `로그인 중이에요`; subtitle: Medium 15,
  `잠시만 기다려주세요`.
- A session-restore retry uses this same static login-loading screen.

### Session restoration splash

- Every cold launch begins with `logoAni.mp4` centered in a 350 × 350 pt view
  on white, before Login, Agreements or Main can appear.
- Playback uses a muted `AVQueuePlayer` with `AVPlayerLooper`. The 2.033-second
  animation and the initial session decision run concurrently; the splash is
  kept for at least 2.034 seconds and remains visible longer when restoration
  has not finished yet.
- Reduce Motion or a missing video falls back to the centered static
  `soomsilLogo` instead. A retry after a restore failure uses the static blue
  login-loading indicator described above.
- The app-update prompt is deferred until the initial splash finishes. It can
  still appear over the session-recovery screen after a restore failure.

### Agreements (`2:2123`, `2:2161`)

- Title block begins at x=24 near y=120.
- Heading: Bold 28, `유세인트와 함께\n시작해볼까요?`.
- Subtitle: Medium 15, `학사 정보를 안전하게 보려면 동의가 필요해요`.
- All-agree row: 342 × 52–56, radius 4, 1 pt gray border, 24 pt checkbox.
- Required rows use a 20 pt checkbox, red `필수` prefix and 26 pt stack
  spacing.
- Terms and privacy are visible and required.
- Marketing consent is fully implemented but hidden by a false feature flag;
  while hidden it is excluded from visible all-agree and the proceed gate.
- Terms URL:
  `https://app.notion.com/p/3cf5364b6dbf804eac29dced5d4c9001?source=copy_link`
- Privacy URL:
  `https://app.notion.com/p/3cf5364b6dbf805a8904f98c452f0cb1?source=copy_link`
- Agreement legal rows open an in-app `WKWebView` sheet.

### Completion (`2:2207`)

- Center group uses the same measured placement and 112 pt SVG view as
  loading, rendering a 96 pt visible circle.
- Title: Bold 28, `이제 시작해볼까요?`.
- Subtitle: 14, `장학금, 수강신청, 성적 정보를 한 곳에서`.
- Bottom button matches Login and reads `유세인트 시작하기`.

### Root transition contract

Every cold launch starts at `restoringSession`. No saved credentials routes to
Login after the splash; a restored or already-active session routes to the
first incomplete agreement state or directly to Main. A failed restore stays
on the session-recovery screen. Manual login replaces the root with
`loginLoading` and then uses the same agreement/Main decision. Agreement
acceptance and completion use separate versioned `UserDefaults` keys and
persist across logout. If the app closes on the completion screen, the next
launch routes back there after the splash instead of skipping it. These root
replacements do not expose a back button.

## Main shell and Home

- Exactly three visible tabs: Home, Timetable, My. Chapel is reached from Home.
- The custom floating tab bar manually composes its glass appearance from a
  translucent white capsule, inner highlights and a `gray100` outline; it does
  not rely on a native glass-effect API. Items share the available width and
  have a 56 pt content height inside 8 pt outer padding.
- Selected icon/label color is `serviceBlue600`; unselected color is
  `serviceGray500`. Each visible tab swaps its outline asset for the matching
  selected fill asset: `ic_home_fill`, `ic_calender_fill`, or
  `ic_person_fill`.
- Header uses `soomsilLogo` on the left. The notification button is hidden
  until notification support ships.
- Home order: cumulative grade → three stat rows → GPA line graph → centered
  semester-details link → 16 pt gray divider → chapel header/card → shortcuts.
- Chapel is an 8-session course and Pass requires 7 attendances. The card
  shows the attended count out of 8, places the threshold marker at 7/8,
  and includes the remaining-to-Pass copy, divider and blue seat text.
- Shortcut cards are equal-width outlined cards for Graduation Audit and
  Tuition/Scholarship.

## Semester grades

- Back chevron followed by a horizontally scrolling semester chip row.
- Selected chip: white fill, 1 pt blue outline; unselected: gray fill.
- Summer and winter chips are included only when those terms exist in the
  semester-summary response. Selecting either chip queries its exact year and
  `.summer`/`.winter` semester from the grade API.
- GPA number is blue; denominator and labels are gray.
- GPA graph points are distributed across the full plot width: the first and
  last terms sit at the two ends, and `N` terms use `plotWidth / (N - 1)`
  spacing. A single term is centered. The value bubble has reserved top space
  so it cannot overlap the rank summary.
- Keep the existing chart and course API models. Course rows use the supplied
  SSUGrade images. Failed matching must use `UndefinedGrade`, never `F`.

## Chapel detail

- Back chevron only; no centered page title.
- Header copy: `내 자리`; seat number is a large blue string.
- Stats: attendance, absence (with info icon), next attendance date.
- Tapping the absence info icon presents `지각 2회 시 결석 1회 처리` in a
  compact popover. A next attendance date is shown only for a parseable future
  `.unknown` server attendance entry; the app does not fabricate dates.
- Pass progress credits present and excused sessions. One late still receives
  attendance credit; every completed pair of late sessions removes one credit,
  matching the displayed rule.
- Rounded outlined map card embeds the existing immutable seat map and ends
  with centered blue `자리를 확인해주세요`.

## Tuition and scholarship

- Back chevron and a two-item underline tab control.
- Active tab text/underline blue; inactive label gray.
- Rows use separators instead of raised cards. Each shows title, bold amount,
  gray date/details and a trailing status badge.
- Existing loading, retry, empty and refresh behavior remains available.

## Graduation audit

- Use the current white flat accordion in `Frame 2147242437` and
  `Frame 2147242484`, not the historical gray-card design.
- The native navigation header has a black chevron-only back affordance and a
  centered `졸업사정표` title.
- The summary shows `졸업사정결과` and the eligible/ineligible result, followed
  by a divider. Requirement classifications are flat rows separated by lines.
- Every classification is collapsed initially. Tapping its row independently
  expands or collapses that classification and rotates its chevron.
- Expanded content shows requirement, standard/calculated values, nonzero
  difference, and the `충족` / `부족` badge while preserving the existing API
  models and status aliases.
- There is no `과목 상세보기` button, used-subject list, or global detail-mode
  state in this screen.

## Timetable

- Header title `시간표` and divider; centered semester selector below.
- Grid card retains API-derived merged consecutive periods.
- Course colors use the design palette and all existing tap targets remain.
- Tapping a course presents a native SwiftUI sheet, not a pushed screen or a
  custom backdrop. It uses a 274 pt detent, 20 pt corner radius, the system drag
  indicator and white background, with title/professor, day/time/room rows and
  centered `닫기`.

## My and hidden notification work

- Plain white list, section headers and row separators; no outer cards.
- Visible rows: logout, terms, privacy, version.
- A `gray100` divider sits immediately below the My header. Within the visible
  legal rows, the only divider is between terms and privacy; there is no
  divider below privacy.
- Notification setting state, screen and toggle rows exist but the My entry and
  notification section are hidden behind a false feature flag until the server
  notification feature is available.
- My terms/privacy rows push `LegalWebView` with `NavigationStack` destinations.
  Onboarding presents the same URLs and view in a sheet with a close action;
  these entry points intentionally do not share presentation style.

## Detail navigation

- Detail screens that are pushed use the native `NavigationStack` back action
  with a black chevron and no `뒤로` label. Because the native item is retained,
  the standard leading-edge swipe-to-go-back gesture remains enabled.
- `LegalWebView` disables its WebView page-history swipe in both presentation
  styles. When it is pushed from My, this keeps the native screen pop gesture
  authoritative.
