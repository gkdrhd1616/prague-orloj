# 프로젝트 검토 · 2026년 11월 20일

최초 검토 대상은 공개 소스 [c965c3f](https://github.com/gkdrhd1616/prague-orloj/commit/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde)입니다. 앱과 위젯이 같은 천문 계산기와 다이얼을 사용합니다. 우선 수정할 부분은 위치를 알 수 없을 때 표시하는 하늘과, 시스템이 위젯 갱신을 미뤘을 때 표시하는 시각입니다.

## 사용자에게 보이는 오류

| 우선순위 | 재현 조건과 영향 | 수정 방향 |
| --- | --- | --- |
| 높음 | 첫 실행에 위치 권한을 거부하면 미확정 위치가 위도 0°, 경도 0°인 `Current Location`으로 계산됩니다. 앱이 기니만의 하늘을 사용자 위치로 보여 줄 수 있습니다. [초기 좌표](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia/OrlojTimeLocationState.swift#L163) · [앱 계산](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia/ContentView.swift#L40) | 미확정 상태를 명시하고, 측정된 위치·저장된 위치·사용자가 선택한 장소가 있을 때 계산합니다. |
| 높음 | 위젯은 지금 시각의 다이얼 한 장만 제공하고 다음 분에 재호출을 요청합니다. 운영체제가 호출을 미루면 바늘과 태양·달이 이전 시각에 머물 수 있습니다. [위젯 타임라인](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/OrlojWidget/PragueOrlojWidget.swift#L40) · [Apple의 갱신 지침](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) | 앞으로 몇 시간 동안의 천문 위치를 여러 시각으로 계산해 한 타임라인에 제공합니다. |
| 중간 | 프라하를 고르면 다이얼은 50.087°N, 14.421°E를 쓰지만 설정 좌표는 0°, 0°입니다. 여기서 수동 모드로 전환하면 실제 다이얼도 0°, 0°로 이동합니다. [프리셋](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia/OrlojTimeLocationState.swift#L151) | 프리셋 생성 시 모델의 프라하 좌표를 그대로 사용하고 수동 전환 결과를 검증합니다. |
| 중간 | 아피아의 2026년 6월 21일 현지 정오를 모델에 입력하면 태양 고도는 약 52°인데 일출이 다음 날로 잡혀 바빌로니아시는 밤, 낮 진행률은 0%가 됩니다. [일출·일몰 날짜 생성](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia/OrlojClockModel.swift#L1221) | 산출한 사건이 요청한 현지 날짜에 속하는지 검사합니다. 날짜변경선과 서머타임 경계를 함께 테스트합니다. |
| 중간 | 트롬쇠의 실제 위도 69.65°N이 66°로 바뀝니다. 하지에 모델이 01:37 일출과 23:53 일몰을 생성해 백야를 잘못 표현합니다. [좌표 정규화](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia/OrlojClockModel.swift#L368) | 태양·달 계산에 실제 좌표를 보존하고, 투영 가능한 범위는 다이얼을 그릴 때 처리합니다. |
| 낮음 | 프라하 모드에서 VoiceOver가 고정 CET 다이얼 값을 시태양시로 읽습니다. [접근성 설명](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/OrlojWidget/PragueOrlojWidget.swift#L84) | 모드에 맞게 모델의 시간 기준 레이블을 사용합니다. |

## 직접 실행한 검증

Xcode 27.2에서 공개본의 새 빌드 폴더로 검증했습니다.

| 대상 | 결과 |
| --- | --- |
| iPad Pro 13형 M5 시뮬레이터, iPadOS 27.2 | Swift 단위 테스트 47개 중 46개 통과. 실패한 [위치 테스트](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologiaTests/astologia_hologiaTests.swift#L419)는 고정 문구 `Device location`을 기대하지만 구현은 측정된 장소명을 저장합니다. 장소명을 기대하도록 수정할 수 있습니다. |
| 같은 iPad 시뮬레이터의 UI 테스트 | 실행, 회전, 설정, 가이드 이동, 천문 정보 연결을 포함해 9회 실행 모두 통과했습니다. 실행 테스트 하나를 여러 UI 구성에서 반복한 횟수를 포함합니다. 세로 캡처에서 원형 다이얼과 외곽 숫자 고리가 화면 안에 들어온 것을 확인했습니다. |
| macOS Release 앱·위젯 | 서명 없는 빌드 성공. 완성된 앱 안에 위젯 실행 파일과 다이얼 자산 카탈로그가 포함됐습니다. |
| macOS 테스트 타깃 | 컴파일 실패. [화면 회전 테스트](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologiaUITests/astologia_hologiaUITests.swift#L24)가 Mac에도 포함돼 UIKit 전용 타입과 회전 API를 참조합니다. 해당 테스트를 iPadOS로 한정해야 합니다. |

이번 실행으로 확인한 화면은 앱의 시뮬레이터 화면입니다. 실제 홈 화면·Mac 데스크톱의 위젯 배치, 장시간 갱신 간격, 실측 천체력과의 정량 오차는 별도 검증이 필요합니다. 지구·태양·달·활자와 표면의 실물 비교에는 동일 각도의 기준 사진이 필요합니다.

## 최초 공개본의 스토어 제출 준비 상태

- iPadOS와 macOS의 [앱 아이콘 카탈로그](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia/Assets.xcassets/AppIcon.appiconset/Contents.json)에 지정된 이미지가 없습니다.
- 앱과 위젯은 [앱 그룹 UserDefaults](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia/OrlojWidgetLocationSnapshot.swift#L25)를 사용합니다. 두 타깃의 제출 번들에 이 접근 목적에 맞는 개인정보 매니페스트 선언이 필요합니다. Apple은 같은 앱 그룹 구성원 간 설정 공유 사유로 `1C8F.1`을 안내합니다. [Apple의 API 사용 사유](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- macOS의 Release 빌드 설정에서 앱의 App Sandbox는 켜져 있고 위젯은 꺼져 있습니다. 위젯 타깃의 샌드박스를 구성한 뒤 서명된 앱과 확장에서 그룹 데이터 공유를 검증해야 합니다. [위젯 설정](https://github.com/gkdrhd1616/prague-orloj/blob/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde/astologia%20hologia.xcodeproj/project.pbxproj#L341) · [Apple의 샌드박스 안내](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)

## 서울에서 재현한 시간 차이

2026년 11월 20일 서울(북위 37.5665°, 동경 126.9780°)의 한국 표준시 정오로 고정하고, 최초 공개본에서 실제 그리기에 사용하는 금색 손의 방향을 고정 로마 숫자 눈금의 24시간 값으로 환산했습니다.

| 확인한 값 | 결과 |
| --- | --- |
| 서울 현지 시각 | 12:00:00 KST |
| 최초 공개본의 금색 손 | 11:42:22, 한국 표준시보다 17분 38초 이른 시각을 표시 |
| 미 해군천문대의 태양 좌표 근사식으로 구한 서울 시태양시 | 약 11:42:24 |
| 프라하 원형 모드에서 현지 정오 | 겨울 12:00 CET, 서머타임 중 11:00 CET |

서울 값은 시태양시와 표준시의 차이를 보여 줍니다. 시태양시는 태양이 그 장소의 자오선을 통과할 때를 정오로 삼습니다. 표준시와의 차이는 관측 경도와 날짜에 따라 달라집니다. 같은 서울에서도 2026년 2월 11일의 현지 정오에 이전 금색 손은 11:13:41을 가리켰습니다. [미 해군천문대의 계산식](https://aa.usno.navy.mil/faq/sun_approx)

실물에서 금색 손은 고정된 안쪽 로마 숫자에 중앙유럽 표준시를 가리킵니다. 맨 바깥 금색 고딕 숫자에서는 같은 손으로 일몰을 기준으로 한 옛 보헤미아 시각을 읽습니다. 해가 질 때 바깥 고리가 24, 한 시간 뒤에는 1을 가리킵니다. [프라하 관광청 자료](https://prague.eu/en/objevujte/old-town-hall-with-astronomical-clock-staromestska-radnice-s-orlojem)

이와 별도로 최초 공개본은 앱을 23:59:47에 열면 다음 분이 00:00:47에 화면에 반영될 수 있었습니다. 수정본은 앱을 열 때 현재 시각으로 계산하고 이후 매분 정각에 갱신합니다. 위젯은 5분 간격으로 약 두 시간 분량의 다이얼 위치를 예약하고 한 시간 뒤 새 타임라인을 요청합니다. 운영체제가 예약대로 표시할 때 이전 항목이 가리키는 시각은 5분 미만 차이가 납니다. 실제 기기의 표시 시점은 운영체제가 정합니다. [Apple 위젯 갱신 안내](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)

## 수정본 검증

- My Sky의 금색 손은 현지 시태양시를 유지합니다. 실제 손에서 사용하는 각도를 로마 숫자 눈금에 환산해 서울의 독립 계산값과 5초 이내인지 확인하는 테스트를 추가했습니다. 프라하의 겨울·여름과 일몰 눈금의 24 정렬도 검증합니다.
- 최초 실행에서 위치를 받지 못하면 위치 설정을 표시합니다. 유효한 위치가 확인된 뒤 다이얼을 계산하며, 프라하 프리셋에서 수동으로 전환해도 프라하 좌표가 유지됩니다.
- 고위도 관측에는 실제 위도를 사용합니다. 백야나 극야에는 그날의 일출·일몰이 없음을 표시하며, 날짜변경선 주변에서는 선택한 장소의 현지 날짜에 맞는 사건을 찾습니다.
- iPad Pro 13형 M5 시뮬레이터에서 단위 테스트 53개와 UI 테스트 10회가 모두 통과했습니다. UI 횟수에는 여러 화면 구성에서 반복한 실행 테스트가 포함됩니다.
- Mac에서 Release 앱과 위젯, 테스트 타깃을 빌드했습니다. 새 금색 손 테스트 2개도 Mac에서 통과했습니다. 대형 위젯 뷰를 688×688 픽셀로 렌더링해 아래쪽 테두리와 고딕 숫자가 보이는지 확인했습니다. 실제 데스크톱 배치와 운영체제의 장시간 갱신 간격은 측정하지 않았습니다.
- 실제 다이얼을 사용한 앱 아이콘, 앱과 위젯의 앱 그룹 설정용 개인정보 매니페스트, Mac 위젯의 샌드박스를 추가했습니다. iOS Release 아카이브에서 앱과 위젯의 버전(1.0, 빌드 1), 양쪽 매니페스트, 앱 아이콘을 확인했습니다.

서명된 iOS 1.0 빌드 1에서 앱과 위젯 양쪽의 서명 및 프로필에 동일한 앱 그룹이 포함된 것을 확인했습니다. 유선 연결한 iPad에 설치한 뒤 기기에서 버전과 빌드 번호를 조회하고 앱을 실행했습니다. 같은 아카이브의 App Store Connect 업로드가 성공했습니다.
