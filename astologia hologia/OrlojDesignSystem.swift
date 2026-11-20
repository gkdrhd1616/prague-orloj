//
//  OrlojDesignSystem.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import SwiftUI

enum OrlojDesignSystem {
    static let background = Color(red: 0.035, green: 0.030, blue: 0.024)
    static let stoneDeep = Color(red: 0.026, green: 0.022, blue: 0.018)
    static let stoneDark = Color(red: 0.066, green: 0.052, blue: 0.036)
    static let stone = Color(red: 0.112, green: 0.088, blue: 0.058)
    static let face = Color(red: 0.065, green: 0.052, blue: 0.038)
    static let ink = Color(red: 0.035, green: 0.045, blue: 0.065)
    static let night = Color(red: 0.035, green: 0.045, blue: 0.065)
    static let twilight = Color(red: 0.55, green: 0.27, blue: 0.21)
    static let daylight = Color(red: 0.20, green: 0.48, blue: 0.66)
    // Plate paint sampled from a 2013 daylight photograph of the dial and
    // neutralised for the warm sunlight in it: teal sky, ochre twilight,
    // charcoal night, slate-blue zodiac band and outer ring.
    static let plateDay = Color(red: 0.50, green: 0.68, blue: 0.69)
    static let plateBelowHorizon = Color(red: 0.18, green: 0.095, blue: 0.075)
    static let plateTwilight = Color(red: 0.79, green: 0.56, blue: 0.21)
    static let plateNight = Color(red: 0.085, green: 0.092, blue: 0.11)
    static let earth = Color(red: 0.12, green: 0.31, blue: 0.39)
    static let gold = Color(red: 0.84, green: 0.68, blue: 0.30)
    static let sun = Color(red: 0.96, green: 0.84, blue: 0.49)
    static let copper = Color(red: 0.42, green: 0.19, blue: 0.105)
    static let verdigris = Color(red: 0.22, green: 0.36, blue: 0.34)
    static let parchment = Color(red: 0.82, green: 0.76, blue: 0.60)
    static let text = Color(red: 0.82, green: 0.76, blue: 0.60)
    static let textMuted = Color(red: 0.55, green: 0.49, blue: 0.37)

    static let dayBlue = Color(red: 0.20, green: 0.48, blue: 0.66)
    static let nightDark = Color(red: 0.035, green: 0.045, blue: 0.065)
    static let twilightOchre = Color(red: 0.55, green: 0.27, blue: 0.21)
    static let brassGold = Color(red: 0.84, green: 0.68, blue: 0.30)
    static let highlightGold = Color(red: 0.96, green: 0.84, blue: 0.49)
    static let darkBrass = Color(red: 0.47, green: 0.33, blue: 0.12)
    static let ivoryText = Color(red: 0.92, green: 0.82, blue: 0.56)
    static let enamelDark = Color(red: 0.035, green: 0.029, blue: 0.023)
    static let enamelBlueBlack = Color(red: 0.055, green: 0.075, blue: 0.11)
    static let zodiacBlue = Color(red: 0.36, green: 0.40, blue: 0.49)
    static let outerRingSlate = Color(red: 0.36, green: 0.40, blue: 0.51)
    static let agedGoldEdge = Color(red: 0.64, green: 0.47, blue: 0.18)
    static let moonSilver = Color(red: 0.82, green: 0.84, blue: 0.80)
    static let moonDarkMetal = Color(red: 0.09, green: 0.086, blue: 0.078)
    static let oxidizedBrass = Color(red: 0.24, green: 0.18, blue: 0.095)
    static let wornGilding = Color(red: 0.62, green: 0.47, blue: 0.22)
    static let shadowBrown = Color(red: 0.09, green: 0.055, blue: 0.033)
    static let burntUmber = Color(red: 0.32, green: 0.135, blue: 0.075)
    static let ironGrey = Color(red: 0.25, green: 0.26, blue: 0.27)
    static let ironHighlight = Color(red: 0.62, green: 0.64, blue: 0.65)

    static let drawerCornerRadius: CGFloat = 8
    static let controlCornerRadius: CGFloat = 8
}

enum OrlojLayerFocus: String, CaseIterable, Identifiable {
    case all = "All"
    case sun = "Sun"
    case moon = "Moon"
    case zodiac = "Zodiac"
    case timeRings = "Time rings"
    case horizon = "Horizon"
    case twilight = "Twilight"
    case unequalHours = "Unequal hours"
    case sidereal = "Sidereal"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .all:
            "circle.grid.cross"
        case .sun:
            "sun.max"
        case .moon:
            "moonphase.waxing.gibbous"
        case .zodiac:
            "circle.dashed"
        case .timeRings:
            "clock.badge"
        case .horizon:
            "sun.horizon"
        case .twilight:
            "moon.stars"
        case .unequalHours:
            "rays"
        case .sidereal:
            "scope"
        }
    }
}

enum OrlojDialMode: String, CaseIterable, Identifiable {
    case display = "Display"
    case guide = "Guide"
    case debug = "Debug"

    var id: String {
        rawValue
    }

    var detail: String {
        switch self {
        case .display:
            "Finished dial with minimal labels."
        case .guide:
            "Teaching view for the selected concept."
        case .debug:
            "Projection labels and technical readouts."
        }
    }
}

enum OrlojGuideLayerID: String, CaseIterable, Identifiable {
    case romanTimeRing
    case romanNumerals
    case civilHourTicks
    case oldCzechRing
    case outer24Numerals
    case sunsetAlignmentMarker
    case sunMarker
    case sunHand
    case solarLongitudePoint
    case eclipticPosition
    case moonMarker
    case moonPhase
    case lunarPosition
    case zodiacRing
    case zodiacGlyphs
    case eclipticPath
    case horizonCurve
    case ortusLabel
    case occasusLabel
    case twilightBand
    case auroraLabel
    case crepusculumLabel
    case nightBoundary
    case unequalHourLines
    case daylightHourCurves
    case ariesStar
    case siderealReference
    case zodiacZeroPoint
    case tropicCancer
    case tropicCapricorn
    case earthDisk
    case castShadows
    case debugProjectionLines

    var id: String {
        rawValue
    }
}

enum OrlojGuideTopicID: String, CaseIterable, Identifiable {
    case romanTime
    case oldCzechTime
    case sun
    case moon
    case zodiacRing
    case horizon
    case twilight
    case unequalHours
    case siderealAries
    case tropics
    case earthAndPlate
    case lightAndShadow

    var id: String {
        rawValue
    }
}

enum OrlojDrawerTab: String, CaseIterable, Identifiable {
    case settings = "Settings"
    case astronomy = "Astronomy"
    case guide = "Guide"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .settings:
            "slider.horizontal.3"
        case .astronomy:
            "sun.horizon"
        case .guide:
            "book"
        }
    }

    static func launchArgumentValue(in arguments: [String]) -> OrlojDrawerTab? {
        guard let index = arguments.firstIndex(of: "-uiTestingDrawerTab"),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        return OrlojDrawerTab(rawValue: arguments[index + 1])
    }
}
