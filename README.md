# Prague Orloj · 프라하 천문시계

프라하 구시청사 천문시계의 상부 다이얼을 SwiftUI로 재현한 iPadOS·macOS 앱입니다. 황도 고리 위의 태양과 달, 달의 위상, 일몰을 기준으로 도는 바깥 24시간 눈금을 한 화면에서 읽을 수 있습니다. 대형 정사각형 위젯도 앱과 같은 다이얼을 그립니다.

**My Sky**는 현재 위치 또는 직접 고른 좌표의 하늘을 계산합니다. 안쪽 로마 숫자는 금색 손으로 현지 시태양시를 읽습니다. 위쪽 XII는 태양이 그곳의 자오선을 지나는 정오입니다. 맨 바깥 고딕 숫자는 일몰 순간을 24로 두고 그 뒤 몇 시간이 지났는지 보여 줍니다. 시간대 기준의 현지 시각은 앱의 천문 정보에서 확인할 수 있습니다. **Prague Orloj**를 선택하면 금색 손은 연중 CET(UTC+1)를 따릅니다. 위젯은 앱에서 마지막으로 저장한 위치를 이용합니다.

## 실행

1. Xcode에서 `astologia hologia.xcodeproj`를 엽니다. 검토에 사용한 버전은 Xcode 27.2이고, iPadOS·macOS 배포 대상은 26.2 이상입니다.
2. `astologia hologia` 스킴과 iPad 시뮬레이터 또는 Mac을 고릅니다. iPad 시뮬레이터에서 Run으로 앱을 실행하거나 Test로 기존 테스트를 실행할 수 있습니다.
3. 실제 기기에서 본인 계정으로 서명할 때는 앱과 위젯 양쪽의 Team 및 Bundle Identifier를 설정합니다. 두 타깃의 App Group과 `OrlojWidgetLocationSnapshot.appGroupIdentifier`에는 본인이 등록한 동일한 그룹 식별자를 사용합니다.

## 구현과 검토

천문 계산은 [OrlojClockModel.swift](astologia%20hologia/OrlojClockModel.swift), 다이얼 조형과 표면 묘사는 [OrlojClockView.swift](astologia%20hologia/OrlojClockView.swift)와 함께 사용하는 렌더러들에 있습니다. 구성, 실행한 테스트, 재현된 오류와 출시 전에 필요한 작업은 [프로젝트 검토](REVIEW.md)에 기록했습니다.

## 미술 자료

고딕 숫자, 황도 별자리 문양과 역사적 지구 도안은 donchico의 2016년 작품 *Prague Astronomical Clock*에서 추출했습니다. 원본 도안은 CC0 1.0으로 공개되어 있습니다. 세부 조형은 사진 자료를 참고한 시각적 재구성입니다. [원본과 이용 조건](https://commons.wikimedia.org/wiki/File:Prague_Astronomical_Clock.svg) · [벡터 추출과 보정 방법](tools/reference-assets/README.md)
