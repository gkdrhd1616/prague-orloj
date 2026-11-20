# 프로젝트 검토 · 2026년 11월 20일

검토 대상은 공개 소스 [c965c3f](https://github.com/gkdrhd1616/prague-orloj/commit/c965c3fd02bcaeaa226fd4e82ec6067a24d1bcde)입니다. 앱과 위젯이 같은 천문 계산기와 다이얼을 사용합니다. 우선 수정할 부분은 위치를 알 수 없을 때 표시하는 하늘과, 시스템이 위젯 갱신을 미뤘을 때 표시하는 시각입니다.

## 사용자에게 보이는 오류

| 우선순위 | 재현 조건과 영향 | 수정 방향 |
| --- | --- | --- |
| 높음 | 첫 실행에 위치 권한을 거부하면 미확정 위치가 위도 0°, 경도 0°인 `Current Location`으로 계산됩니다. 앱이 기니만의 하늘을 사용자 위치로 보여 줄 수 있습니다. [초기 좌표](astologia%20hologia/OrlojTimeLocationState.swift#L163) · [앱 계산](astologia%20hologia/ContentView.swift#L40) | 미확정 상태를 명시하고, 측정된 위치·저장된 위치·사용자가 선택한 장소가 있을 때 계산합니다. |
| 높음 | 위젯은 지금 시각의 다이얼 한 장만 제공하고 다음 분에 재호출을 요청합니다. 운영체제가 호출을 미루면 바늘과 태양·달이 이전 시각에 머물 수 있습니다. [위젯 타임라인](OrlojWidget/PragueOrlojWidget.swift#L40) · [Apple의 갱신 지침](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) | 앞으로 몇 시간 동안의 천문 위치를 여러 시각으로 계산해 한 타임라인에 제공합니다. |
| 중간 | 프라하를 고르면 다이얼은 50.087°N, 14.421°E를 쓰지만 설정 좌표는 0°, 0°입니다. 여기서 수동 모드로 전환하면 실제 다이얼도 0°, 0°로 이동합니다. [프리셋](astologia%20hologia/OrlojTimeLocationState.swift#L151) | 프리셋 생성 시 모델의 프라하 좌표를 그대로 사용하고 수동 전환 결과를 검증합니다. |
| 중간 | 아피아의 2026년 6월 21일 현지 정오를 모델에 입력하면 태양 고도는 약 52°인데 일출이 다음 날로 잡혀 바빌로니아시는 밤, 낮 진행률은 0%가 됩니다. [일출·일몰 날짜 생성](astologia%20hologia/OrlojClockModel.swift#L1221) | 산출한 사건이 요청한 현지 날짜에 속하는지 검사합니다. 날짜변경선과 서머타임 경계를 함께 테스트합니다. |
| 중간 | 트롬쇠의 실제 위도 69.65°N이 66°로 바뀝니다. 하지에 모델이 01:37 일출과 23:53 일몰을 생성해 백야를 잘못 표현합니다. [좌표 정규화](astologia%20hologia/OrlojClockModel.swift#L368) | 태양·달 계산에 실제 좌표를 보존하고, 투영 가능한 범위는 다이얼을 그릴 때 처리합니다. |
| 낮음 | 프라하 모드에서 VoiceOver가 고정 CET 다이얼 값을 시태양시로 읽습니다. [접근성 설명](OrlojWidget/PragueOrlojWidget.swift#L84) | 모드에 맞게 모델의 시간 기준 레이블을 사용합니다. |

## 직접 실행한 검증

Xcode 27.2에서 공개본의 새 빌드 폴더로 검증했습니다.

| 대상 | 결과 |
| --- | --- |
| iPad Pro 13형 M5 시뮬레이터, iPadOS 27.2 | Swift 단위 테스트 47개 중 46개 통과. 실패한 [위치 테스트](astologia%20hologiaTests/astologia_hologiaTests.swift#L419)는 고정 문구 `Device location`을 기대하지만 구현은 측정된 장소명을 저장합니다. 장소명을 기대하도록 수정할 수 있습니다. |
| 같은 iPad 시뮬레이터의 UI 테스트 | 실행, 회전, 설정, 가이드 이동, 천문 정보 연결을 포함해 9회 실행 모두 통과했습니다. 실행 테스트 하나를 여러 UI 구성에서 반복한 횟수를 포함합니다. 세로 캡처에서 원형 다이얼과 외곽 숫자 고리가 화면 안에 들어온 것을 확인했습니다. |
| macOS Release 앱·위젯 | 서명 없는 빌드 성공. 완성된 앱 안에 위젯 실행 파일과 다이얼 자산 카탈로그가 포함됐습니다. |
| macOS 테스트 타깃 | 컴파일 실패. [화면 회전 테스트](astologia%20hologiaUITests/astologia_hologiaUITests.swift#L24)가 Mac에도 포함돼 UIKit 전용 타입과 회전 API를 참조합니다. 해당 테스트를 iPadOS로 한정해야 합니다. |

이번 실행으로 확인한 화면은 앱의 시뮬레이터 화면입니다. 실제 홈 화면·Mac 데스크톱의 위젯 배치, 장시간 갱신 간격, 실측 천체력과의 정량 오차는 별도 검증이 필요합니다. 지구·태양·달·활자와 표면의 실물 비교에는 동일 각도의 기준 사진이 필요합니다.

## 스토어 제출 전

- iPadOS와 macOS의 [앱 아이콘 카탈로그](astologia%20hologia/Assets.xcassets/AppIcon.appiconset/Contents.json)에 지정된 이미지가 없습니다.
- 앱과 위젯은 [앱 그룹 UserDefaults](astologia%20hologia/OrlojWidgetLocationSnapshot.swift#L25)를 사용합니다. 두 타깃의 제출 번들에 이 접근 목적에 맞는 개인정보 매니페스트 선언이 필요합니다. Apple은 같은 앱 그룹 구성원 간 설정 공유 사유로 `1C8F.1`을 안내합니다. [Apple의 API 사용 사유](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- macOS의 Release 빌드 설정에서 앱의 App Sandbox는 켜져 있고 위젯은 꺼져 있습니다. 위젯 타깃의 샌드박스를 구성한 뒤 서명된 앱과 확장에서 그룹 데이터 공유를 검증해야 합니다. [위젯 설정](astologia%20hologia.xcodeproj/project.pbxproj#L341) · [Apple의 샌드박스 안내](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
