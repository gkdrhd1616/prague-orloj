//
//  OrlojGuideCatalog.swift
//  astologia hologia
//
//  Created by Codex on 5/13/26.
//

import Foundation

struct OrlojGuideItem: Identifiable, Equatable {
    let id: OrlojGuideTopicID
    let title: String
    let subtitle: String?
    let shortDescription: String
    let longDescription: String?
    let targetLayers: [OrlojGuideLayerID]
    let currentValue: OrlojGuideCurrentValueID?
    let calloutLabel: String?
    let systemImage: String
    let focus: OrlojLayerFocus

    var targetLayerSet: Set<OrlojGuideLayerID> {
        Set(targetLayers)
    }
}

struct OrlojResolvedGuideItem: Identifiable, Equatable {
    let item: OrlojGuideItem
    let currentValue: String?

    var id: OrlojGuideTopicID {
        item.id
    }

    var title: String {
        item.title
    }

    var subtitle: String? {
        item.subtitle
    }

    var shortDescription: String {
        item.shortDescription
    }

    var longDescription: String? {
        item.longDescription
    }

    var targetLayers: [OrlojGuideLayerID] {
        item.targetLayers
    }

    var targetLayerSet: Set<OrlojGuideLayerID> {
        item.targetLayerSet
    }

    var calloutLabel: String? {
        item.calloutLabel
    }

    var systemImage: String {
        item.systemImage
    }

    var focus: OrlojLayerFocus {
        item.focus
    }
}

enum OrlojGuideCurrentValueID: String, CaseIterable {
    case localTime
    case oldCzechTime
    case sun
    case moon
    case zodiac
    case horizon
    case twilight
    case unequalHours
    case sidereal
    case tropics
}

enum OrlojGuideCatalog {
    static let items: [OrlojGuideItem] = [
        OrlojGuideItem(
            id: .romanTime,
            title: "Roman time",
            subtitle: "Two sets of twelve ordinary hours",
            shortDescription: "The Roman scale reads CET in Prague mode and apparent solar time in My Sky. One daily revolution covers two sets of twelve hours.",
            longDescription: "Prague mode keeps the golden hand on uniform Central European Time (UTC+1), without daylight saving. My Sky follows the calculated Sun, so its hand reads apparent solar time. Modern local civil time is listed separately in both modes.",
            targetLayers: [.romanTimeRing, .romanNumerals, .civilHourTicks],
            currentValue: .localTime,
            calloutLabel: "Fixed ordinary time scale",
            systemImage: "clock",
            focus: .timeRings
        ),
        OrlojGuideItem(
            id: .oldCzechTime,
            title: "Old Czech Time",
            subtitle: "Hours since sunset",
            shortDescription: "This outer ring counts hours from sunset. The number 24 aligns with sunset.",
            longDescription: "The outer hour ring is a moving scale. Numeral 24 aligns with the hand at calculated sunset. Prague uses its CET hand; My Sky uses the Sun's apparent solar angle. Sunset calculations use the geometric horizon, without atmospheric refraction.",
            targetLayers: [.oldCzechRing, .outer24Numerals, .sunsetAlignmentMarker],
            currentValue: .oldCzechTime,
            calloutLabel: "24 = sunset",
            systemImage: "clock.badge",
            focus: .timeRings
        ),
        OrlojGuideItem(
            id: .sun,
            title: "Sun",
            subtitle: "Time hand and zodiac position",
            shortDescription: "In Prague mode, the Sun sits where the CET hand meets the zodiac. My Sky uses the calculated solar position.",
            longDescription: "Prague mode is an idealized reconstruction of the dial, not an exact simulation of its historical gears. Astronomy readouts retain the calculated real-sky Sun position, which can differ from the clock mechanism.",
            targetLayers: [.sunMarker, .sunHand, .solarLongitudePoint, .eclipticPosition],
            currentValue: .sun,
            calloutLabel: "Sun on the ecliptic",
            systemImage: "sun.max",
            focus: .sun
        ),
        OrlojGuideItem(
            id: .moon,
            title: "Moon",
            subtitle: "Lunar position and phase",
            shortDescription: "The Prague Moon follows the ecliptic and shows its phase. My Sky includes the Moon's calculated ecliptic latitude.",
            longDescription: "The idealized Prague dial constrains the Moon to the zodiac track while retaining its calculated longitude and phase. The underlying lunar coordinates and astronomy readouts remain unchanged.",
            targetLayers: [.moonMarker, .moonPhase, .lunarPosition],
            currentValue: .moon,
            calloutLabel: "Moon phase",
            systemImage: "moonphase.waxing.gibbous",
            focus: .moon
        ),
        OrlojGuideItem(
            id: .zodiacRing,
            title: "Zodiac ring",
            subtitle: "Projected ecliptic",
            shortDescription: "조디악은 중심 장식 원이 아니라 stereographic projection의 편심 황도입니다.",
            longDescription: "The zodiac follows the projected ecliptic. It is intentionally eccentric, because it is part of the astrolabe geometry.",
            targetLayers: [.zodiacRing, .zodiacGlyphs, .eclipticPath],
            currentValue: .zodiac,
            calloutLabel: "Eccentric projected ecliptic",
            systemImage: "circle.dashed",
            focus: .zodiac
        ),
        OrlojGuideItem(
            id: .horizon,
            title: "Horizon",
            subtitle: "Sunrise and sunset boundary",
            shortDescription: "The horizon separates the visible sky from the sky below it. ORTUS and OCCASUS mark sunrise and sunset.",
            longDescription: "Astronomy readouts give calculated sunrise and sunset. My Sky uses the calculated Sun position; the Prague clock mechanism approximates its passage across the horizon.",
            targetLayers: [.horizonCurve, .ortusLabel, .occasusLabel],
            currentValue: .horizon,
            calloutLabel: "Sun crosses ORTUS and OCCASUS",
            systemImage: "sun.horizon",
            focus: .horizon
        ),
        OrlojGuideItem(
            id: .twilight,
            title: "Twilight",
            subtitle: "Dawn and dusk band",
            shortDescription: "붉은 띠는 horizon과 astronomical night boundary 사이의 dawn/dusk 영역입니다.",
            longDescription: "The ochre band reads the transitional sky between the horizon and astronomical night boundary.",
            targetLayers: [.twilightBand, .auroraLabel, .crepusculumLabel, .nightBoundary],
            currentValue: .twilight,
            calloutLabel: "Band before night boundary",
            systemImage: "moon.stars",
            focus: .twilight
        ),
        OrlojGuideItem(
            id: .unequalHours,
            title: "Unequal hours",
            subtitle: "Seasonal daylight divisions",
            shortDescription: "굽은 daylight hour lines는 계절별 낮 시간을 12부분으로 나눕니다.",
            longDescription: "These curves divide the daylight interval into 12 temporal parts, so they bend with the seasonal Sun path.",
            targetLayers: [.unequalHourLines, .daylightHourCurves],
            currentValue: .unequalHours,
            calloutLabel: "Daylight divided into 12",
            systemImage: "rays",
            focus: .unequalHours
        ),
        OrlojGuideItem(
            id: .siderealAries,
            title: "Sidereal star",
            subtitle: "Vernal equinox reference",
            shortDescription: "Aries star는 춘분점 기준점이며 local sidereal time의 관계를 보여줍니다.",
            longDescription: "The Aries marker is the zodiac zero point. Its position against the time scale gives a sidereal reading.",
            targetLayers: [.ariesStar, .siderealReference, .zodiacZeroPoint],
            currentValue: .sidereal,
            calloutLabel: "Vernal equinox reference",
            systemImage: "scope",
            focus: .sidereal
        ),
        OrlojGuideItem(
            id: .tropics,
            title: "Tropics / ecliptic motion",
            subtitle: "Seasonal radial motion",
            shortDescription: "태양은 여름에는 바깥 Cancer 쪽으로, 겨울에는 안쪽 Capricorn 쪽으로 움직입니다.",
            longDescription: "The projected tropics explain why the Sun sits farther outward in northern summer and closer inward in winter.",
            targetLayers: [.tropicCancer, .tropicCapricorn, .eclipticPath, .sunMarker],
            currentValue: .tropics,
            calloutLabel: "Summer outward, winter inward",
            systemImage: "arrow.up.and.down.circle",
            focus: .zodiac
        )
    ]

    static func item(for id: OrlojGuideTopicID?) -> OrlojGuideItem? {
        guard let id else {
            return nil
        }

        return items.first { $0.id == id }
    }

    static func resolvedItems(readout: OrlojAstronomyReadout) -> [OrlojResolvedGuideItem] {
        items.map { item in
            OrlojResolvedGuideItem(item: item, currentValue: currentValue(for: item, readout: readout))
        }
    }

    static func resolvedItem(for id: OrlojGuideTopicID?, readout: OrlojAstronomyReadout) -> OrlojResolvedGuideItem? {
        guard let item = item(for: id) else {
            return nil
        }

        return OrlojResolvedGuideItem(item: item, currentValue: currentValue(for: item, readout: readout))
    }

    static func currentValue(for item: OrlojGuideItem, readout: OrlojAstronomyReadout) -> String? {
        guard let currentValue = item.currentValue else {
            return nil
        }

        switch currentValue {
        case .localTime:
            return "\(readout.dialTime) \(readout.dialTimeZone)"
        case .oldCzechTime:
            return readout.oldCzechHour
        case .sun:
            return "Sky: \(readout.zodiacName) · altitude \(readout.sunAltitude)"
        case .moon:
            return "\(readout.moonPhase) · \(readout.moonIllumination) lit"
        case .zodiac:
            return "Sky: \(readout.zodiacName) · \(readout.solarEclipticLongitude)"
        case .horizon:
            return "\(readout.sunrise) / \(readout.sunset)"
        case .twilight:
            return readout.dawnDusk
        case .unequalHours:
            return "\(readout.babylonianHour) · daylight \(readout.daylightProgress)"
        case .sidereal:
            return readout.siderealTime
        case .tropics:
            return "\(readout.solarTropicPosition) · \(readout.solarDeclination)"
        }
    }

    static func currentValue(for item: OrlojGuideItem, state: OrlojClockState) -> String? {
        guard let currentValue = item.currentValue else {
            return nil
        }

        switch currentValue {
        case .localTime:
            return "\(state.dialTimeString) \(state.dialTimeZoneLabel)"
        case .oldCzechTime:
            return state.oldCzechHourLabel
        case .sun:
            return "Sky: \(state.zodiacSign.name) · altitude \(state.sunAltitudeLabel)"
        case .moon:
            return "\(state.lunar.phaseName) · \(state.moonIlluminationLabel) lit"
        case .zodiac:
            return "Sky: \(state.zodiacSign.name) · \(state.solarEclipticLongitudeLabel)"
        case .horizon:
            return "\(state.sunriseTimeString) / \(state.sunsetTimeString)"
        case .twilight:
            return state.twilightIntervalLabel
        case .unequalHours:
            return "\(state.babylonianHourLabel) · \(state.daylightProgressLabel)"
        case .sidereal:
            return state.siderealTimeString
        case .tropics:
            return "\(state.solarTropicPositionLabel) · \(state.solarDeclinationLabel)"
        }
    }
}
