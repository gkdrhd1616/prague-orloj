# 다이얼 벡터 재생성

앱 빌드에는 Xcode 자산 카탈로그에 포함된 SVG를 사용합니다. 도안을 다시 추출할 때는 donchico의 [원본 SVG](https://upload.wikimedia.org/wikipedia/commons/2/26/Prague_Astronomical_Clock.svg)를 이 폴더에 `Prague_Astronomical_Clock.svg`로 저장합니다. 추출 스크립트가 입력의 SHA-256을 확인합니다. [원작자와 CC0 1.0 기록](https://commons.wikimedia.org/wiki/File:Prague_Astronomical_Clock.svg)

프로젝트 루트에서 다음 명령을 사용합니다.

```sh
python3 tools/reference-assets/extract_assets.py
python3 tools/reference-assets/refine_lettering.py
```

첫 스크립트는 Python 표준 라이브러리와 함께 제공된 좌표 메타데이터를 사용합니다. 두 번째는 numpy, svgpathtools 1.7.2, shapely 2.0.7을 사용해 숫자 폭과 별자리 문양의 획을 보정합니다.
