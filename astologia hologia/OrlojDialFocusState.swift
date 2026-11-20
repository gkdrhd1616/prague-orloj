//
//  OrlojDialFocusState.swift
//  astologia hologia
//
//  Created by Codex on 5/13/26.
//

import Foundation

struct OrlojDialFocusState: Equatable {
    var mode: OrlojDialMode
    var focus: OrlojLayerFocus
    var activeGuideItemId: OrlojGuideTopicID?
    var targetLayers: Set<OrlojGuideLayerID>
    var showAnnotations: Bool

    static let display = OrlojDialFocusState(
        mode: .display,
        focus: .all,
        activeGuideItemId: nil,
        targetLayers: [],
        showAnnotations: false
    )

    static let debug = OrlojDialFocusState(
        mode: .debug,
        focus: .all,
        activeGuideItemId: nil,
        targetLayers: [.debugProjectionLines],
        showAnnotations: true
    )

    static func manualFocus(_ focus: OrlojLayerFocus) -> OrlojDialFocusState {
        guard focus != .all else {
            return .display
        }

        return OrlojDialFocusState(
            mode: .guide,
            focus: focus,
            activeGuideItemId: nil,
            targetLayers: focus.targetLayers,
            showAnnotations: false
        )
    }

    static func guide(item: OrlojResolvedGuideItem) -> OrlojDialFocusState {
        OrlojDialFocusState(
            mode: .guide,
            focus: item.focus,
            activeGuideItemId: item.id,
            targetLayers: item.targetLayerSet,
            showAnnotations: true
        )
    }

    static func readout(item: OrlojResolvedGuideItem) -> OrlojDialFocusState {
        OrlojDialFocusState(
            mode: .guide,
            focus: item.focus,
            activeGuideItemId: nil,
            targetLayers: item.targetLayerSet,
            showAnnotations: false
        )
    }
}

extension OrlojLayerFocus {
    var targetLayers: Set<OrlojGuideLayerID> {
        switch self {
        case .all:
            []
        case .sun:
            [.sunMarker, .sunHand, .solarLongitudePoint, .eclipticPosition]
        case .moon:
            [.moonMarker, .moonPhase, .lunarPosition]
        case .zodiac:
            [.zodiacRing, .zodiacGlyphs, .eclipticPath, .solarLongitudePoint, .eclipticPosition, .tropicCancer, .tropicCapricorn]
        case .timeRings:
            [.romanTimeRing, .romanNumerals, .civilHourTicks, .oldCzechRing, .outer24Numerals, .sunsetAlignmentMarker]
        case .horizon:
            [.horizonCurve, .ortusLabel, .occasusLabel]
        case .twilight:
            [.twilightBand, .auroraLabel, .crepusculumLabel, .nightBoundary]
        case .unequalHours:
            [.unequalHourLines, .daylightHourCurves]
        case .sidereal:
            [.ariesStar, .siderealReference, .zodiacZeroPoint, .eclipticPath]
        }
    }
}
