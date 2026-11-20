//
//  OrlojGuideCatalog.swift
//  astologia hologia
//
//  Created by Codex on 5/13/26.
//

import Foundation

/// Groups of topics in the reading guide, in the order they are listed.
enum OrlojGuideSection: String, CaseIterable, Identifiable {
    case time = "Reading the time"
    case bodies = "Sun, Moon and zodiac"
    case sky = "The painted sky"
    case light = "Light on the dial"

    var id: String {
        rawValue
    }
}

struct OrlojGuideItem: Identifiable, Equatable {
    let id: OrlojGuideTopicID
    let section: OrlojGuideSection
    let title: String
    let subtitle: String?
    let shortDescription: String
    let longDescription: String?
    /// Numbered steps for reading this element on the dial.
    let readingSteps: [String]
    /// What the element is or does on the clock in Prague's Old Town Square.
    let pragueNote: String?
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

    var section: OrlojGuideSection {
        item.section
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

    var readingSteps: [String] {
        item.readingSteps
    }

    var pragueNote: String? {
        item.pragueNote
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
    case earth
    case light
}

struct OrlojGuideSource: Identifiable, Equatable {
    let title: String
    let url: URL

    var id: String {
        title
    }
}

enum OrlojGuideCatalog {
    // MARK: Introduction

    static let overview = "The dial is a mechanical astrolabe: a fixed painted map of the sky with moving pointers on top. The Sun's position against the painted regions and the rings around them tells the time, the season and whether it is day, twilight or night."

    static let quickSteps = [
        "Find the golden hand with the Sun. Its tip on the gold Roman numerals gives the time.",
        "Look at what is painted behind the Sun: blue sky is day, the ochre band is dawn or dusk, black is night.",
        "Follow the hand outwards to the outer ring: its number counts hours since the last sunset.",
        "Read the zodiac sign beneath the Sun for the season, and the silver-and-black sphere for the Moon's phase."
    ]

    static let pragueModeNote = "Prague Orloj mode shows the clock as it runs in Prague: the hand keeps Central European Time all year and the sky is Prague's."
    static let mySkyModeNote = "My Sky redraws the horizon and twilight for your location; the hand then follows the real Sun, so it reads apparent solar time."

    static let history = "The Prague Orloj was installed on the Old Town Hall tower in 1410, built by the clockmaker Mikuláš of Kadaň with the astronomer Jan Šindel. It is the oldest astronomical clock still working. The calendar dial below it and the moving figures were added later and are not shown here."

    static let sources: [OrlojGuideSource] = [
        OrlojGuideSource(title: "Prague astronomical clock (Wikipedia)",
                         url: URL(string: "https://en.wikipedia.org/wiki/Prague_astronomical_clock")!),
        OrlojGuideSource(title: "How to read time (Prague City Tourism)",
                         url: URL(string: "https://prague.eu/en/how-to-read-time")!),
        OrlojGuideSource(title: "Approximate solar coordinates (US Naval Observatory)",
                         url: URL(string: "https://aa.usno.navy.mil/faq/sun_approx")!)
    ]

    static let creditNote = "The Gothic numerals, zodiac signs and globe are traced from donchico's CC0 drawing of the dial; colours and proportions follow a 2013 photograph of the clock."

    // MARK: Topics

    static let items: [OrlojGuideItem] = [
        OrlojGuideItem(
            id: .romanTime,
            section: .time,
            title: "Roman time",
            subtitle: "Two sets of twelve ordinary hours",
            shortDescription: "The golden hand points to the gold Roman numerals I–XII, which run twice around the dial: XII at the top is noon, XII at the bottom is midnight.",
            longDescription: "The Roman scale is fixed and the golden hand makes one turn a day. In Prague mode the hand keeps Central European Time (UTC+1) all year, so in summer it reads an hour behind the clocks in town. In My Sky it follows the calculated Sun, so XII at the top is the moment the Sun crosses your meridian. Your modern local time is listed separately in the Astronomy tab.",
            readingSteps: [
                "Follow the golden hand to its tip on the Roman numerals.",
                "Read the numeral: top half of the dial for daytime hours, bottom half for night.",
                "Compare with the local time in the Astronomy tab to see the offset of solar or winter time."
            ],
            pragueNote: "In Prague the hand ends in a small gilded hand with an outstretched finger; the dial never switches to summer time.",
            targetLayers: [.romanTimeRing, .romanNumerals, .civilHourTicks],
            currentValue: .localTime,
            calloutLabel: "Fixed ordinary time scale",
            systemImage: "clock",
            focus: .timeRings
        ),
        OrlojGuideItem(
            id: .oldCzechTime,
            section: .time,
            title: "Old Czech time",
            subtitle: "Hours counted from sunset",
            shortDescription: "The outer ring of Gothic numerals counts the hours since sunset. Its 24 sits under the hand at the moment the Sun sets.",
            longDescription: "In medieval Bohemia the day began at sunset. Because sunset moves through the year, the whole outer ring turns slowly so that 24 always meets the hand at sunset. The same golden hand then reads 1, 2, 3… for each hour after it. The app finds sunset on the geometric horizon, without atmospheric refraction.",
            readingSteps: [
                "Find where the golden hand crosses the outer ring of Gothic numerals.",
                "That number is the hours elapsed since the last sunset.",
                "Find 24 on the ring: when the hand reaches it, the Sun sets."
            ],
            pragueNote: "The numerals are painted in Schwabacher script on the outermost ring.",
            targetLayers: [.oldCzechRing, .outer24Numerals, .sunsetAlignmentMarker],
            currentValue: .oldCzechTime,
            calloutLabel: "24 = sunset",
            systemImage: "clock.badge",
            focus: .timeRings
        ),
        OrlojGuideItem(
            id: .unequalHours,
            section: .time,
            title: "Unequal hours",
            subtitle: "Daylight in twelve seasonal parts",
            shortDescription: "The curved gold lines across the blue sky divide each day's daylight into twelve parts, numbered 1–12 in black.",
            longDescription: "Between sunrise and sunset the day always has twelve of these temporal hours, so they are long in summer and short in winter. The curves bend because the Sun's daily path changes with the season. The Astronomy tab lists the current hour as Unequal / Babylonian.",
            readingSteps: [
                "Find the Sun when it is in the blue part of the dial.",
                "Read the black number of the band between the curves it sits in.",
                "That is the current hour of daylight, counted from sunrise."
            ],
            pragueNote: "On the clock the curves and numerals are painted on the fixed plate and only apply while the Sun is above the horizon.",
            targetLayers: [.unequalHourLines, .daylightHourCurves],
            currentValue: .unequalHours,
            calloutLabel: "Daylight divided into 12",
            systemImage: "rays",
            focus: .unequalHours
        ),
        OrlojGuideItem(
            id: .siderealAries,
            section: .time,
            title: "Star time",
            subtitle: "The vernal equinox pointer",
            shortDescription: "A small gold star marks the vernal equinox, the zodiac's zero point. Against the Roman numerals it shows sidereal (star) time.",
            longDescription: "Sidereal time follows the stars rather than the Sun. The star pointer turns with the zodiac ring, a little faster than the Sun's hand: it gains about four minutes a day and one whole turn a year. At the March equinox the star and the Sun point the same way.",
            readingSteps: [
                "Find the small gold star near the Roman numerals.",
                "Read its position on the Roman scale as you would the hand: that is local sidereal time."
            ],
            pragueNote: "The star rides on the zodiac ring's pointer, so it moves with the ring rather than with the Sun.",
            targetLayers: [.ariesStar, .siderealReference, .zodiacZeroPoint],
            currentValue: .sidereal,
            calloutLabel: "Vernal equinox reference",
            systemImage: "scope",
            focus: .sidereal
        ),
        OrlojGuideItem(
            id: .sun,
            section: .bodies,
            title: "Sun",
            subtitle: "The golden hand and its Sun",
            shortDescription: "A gilded Sun slides along the golden hand and always sits on the zodiac ring, at the sign the Sun is in.",
            longDescription: "The hand gives the time; the Sun's place along the hand gives the season, and the painted background behind it shows whether it is day, twilight or night. The app's Prague mode is an idealised reconstruction, not a simulation of the clock's gear train; the Astronomy tab always shows the calculated real Sun.",
            readingSteps: [
                "Find the gilded Sun on the golden hand.",
                "Note the colour behind it: day, twilight or night.",
                "Read the zodiac sign under it for the season."
            ],
            pragueNote: "The hand also carries an iron counterweight tail on the opposite side of the arbor.",
            targetLayers: [.sunMarker, .sunHand, .solarLongitudePoint, .eclipticPosition],
            currentValue: .sun,
            calloutLabel: "Sun on the ecliptic",
            systemImage: "sun.max",
            focus: .sun
        ),
        OrlojGuideItem(
            id: .moon,
            section: .bodies,
            title: "Moon",
            subtitle: "Position and phase",
            shortDescription: "A half-silver, half-black sphere on its own hand shows where the Moon is in the zodiac and, by how much silver shows, its phase.",
            longDescription: "The Moon circles the zodiac in about 27 days, so its hand falls behind the Sun's by roughly 50 minutes a day. The sphere turns as the gap between them grows: all black at new Moon, half and half at the quarters, all silver at full Moon. In Prague mode the Moon is kept on the zodiac track; My Sky also includes its calculated latitude.",
            readingSteps: [
                "Find the silver-and-black sphere on the dark iron hand.",
                "Read how much silver faces you: that is the phase.",
                "Read the zodiac sign beneath it for the Moon's place in the sky."
            ],
            pragueNote: "On the clock the sphere is a hollow ball turned by a mechanism inside it as the Moon's hand moves away from the Sun's.",
            targetLayers: [.moonMarker, .moonPhase, .lunarPosition],
            currentValue: .moon,
            calloutLabel: "Moon phase",
            systemImage: "moonphase.waxing.gibbous",
            focus: .moon
        ),
        OrlojGuideItem(
            id: .zodiacRing,
            section: .bodies,
            title: "Zodiac ring",
            subtitle: "The Sun's yearly path",
            shortDescription: "The off-centre ring is the ecliptic, the Sun's path through the stars, drawn in the same projection as the sky behind it. Its signs run anticlockwise.",
            longDescription: "Because the sky is projected onto a flat plate, the circle of the ecliptic lands off-centre: it touches the Tropic of Cancer on one side and the Tropic of Capricorn on the other. The ring turns once a sidereal day. Its gold ladder marks every 5° of longitude; each sign covers 30°.",
            readingSteps: [
                "Find the sign under the Sun: the Sun is in that sign.",
                "Count the ladder's divisions from the sign's edge to estimate the degree, 5° per step."
            ],
            pragueNote: "On the clock the ring is a separate gilded part standing in front of the plate, so it casts its own shadow.",
            targetLayers: [.zodiacRing, .zodiacGlyphs, .eclipticPath],
            currentValue: .zodiac,
            calloutLabel: "Eccentric projected ecliptic",
            systemImage: "circle.dashed",
            focus: .zodiac
        ),
        OrlojGuideItem(
            id: .tropics,
            section: .bodies,
            title: "Seasons and tropics",
            subtitle: "Why the Sun moves in and out",
            shortDescription: "Through the year the Sun slides along its hand: outward towards the Tropic of Cancer in northern summer, inward towards the Tropic of Capricorn in winter.",
            longDescription: "The two tropics are the circles the Sun follows on the solstices; the equator lies between them. Farther out on the plate means a longer arc above the horizon, which is why summer days are long and the Sun climbs high.",
            readingSteps: [
                "See how far the Sun sits from the centre.",
                "Near the outer gold circle: around the June solstice. Near the inner: around December."
            ],
            pragueNote: nil,
            targetLayers: [.tropicCancer, .tropicCapricorn, .eclipticPath, .sunMarker],
            currentValue: .tropics,
            calloutLabel: "Summer outward, winter inward",
            systemImage: "arrow.up.and.down.circle",
            focus: .zodiac
        ),
        OrlojGuideItem(
            id: .earthAndPlate,
            section: .sky,
            title: "Earth and the fixed plate",
            subtitle: "A painted map of the sky",
            shortDescription: "The blue globe in the centre is the Earth. The painted plate around it does not move: it is the local sky, drawn like a medieval astrolabe.",
            longDescription: "The plate projects the sky onto the plane of the equator. Lines of constant altitude become circles, which is why the horizon and the edge of night are drawn as off-centre arcs. Everything that moves — hands, ring, Sun and Moon — turns over this fixed map.",
            readingSteps: [
                "Treat the plate as your sky: the top is where the Sun stands at noon, the left edge of the blue is the eastern horizon and the right edge the western.",
                "Read every moving part against it."
            ],
            pragueNote: "Prague's plate is drawn for the city's latitude. In My Sky the app redraws it for your location.",
            targetLayers: [.earthDisk],
            currentValue: .earth,
            calloutLabel: "Fixed astrolabe plate",
            systemImage: "globe.europe.africa",
            focus: .horizon
        ),
        OrlojGuideItem(
            id: .horizon,
            section: .sky,
            title: "Horizon",
            subtitle: "Sunrise and sunset",
            shortDescription: "The edge of the blue sky is the horizon. ORTVS on the left marks sunrise in the east; OCCASVS on the right marks sunset in the west.",
            longDescription: "When the Sun reaches the horizon on the left it rises; on the right it sets. The horizon's curve depends on latitude, so My Sky redraws it for your location. The Astronomy tab gives the calculated times.",
            readingSteps: [
                "Watch the Sun near the edge of the blue area.",
                "At ORTVS it rises; at OCCASVS it sets."
            ],
            pragueNote: "ORTVS and OCCASVS are Latin for rising and setting, written in the classical V for U.",
            targetLayers: [.horizonCurve, .ortusLabel, .occasusLabel],
            currentValue: .horizon,
            calloutLabel: "Sun crosses ORTVS and OCCASVS",
            systemImage: "sun.horizon",
            focus: .horizon
        ),
        OrlojGuideItem(
            id: .twilight,
            section: .sky,
            title: "Twilight and night",
            subtitle: "Dawn, dusk and darkness",
            shortDescription: "Below the horizon an ochre band marks twilight — AVRORA, dawn, on the left and CREPVSCVLVM, dusk, on the right. The black disk is full night.",
            longDescription: "The band reaches from the horizon down to the circle where the Sun is 18° below it, the end of astronomical twilight. While the Sun crosses the band the sky is brightening or fading; inside the black disk the sky is fully dark.",
            readingSteps: [
                "Find the Sun below the horizon.",
                "In the ochre band it is dawn (left) or dusk (right).",
                "In the black disk it is night."
            ],
            pragueNote: "The band's colour has changed between restorations; this app follows a 2013 photograph.",
            targetLayers: [.twilightBand, .auroraLabel, .crepusculumLabel, .nightBoundary],
            currentValue: .twilight,
            calloutLabel: "Band before night boundary",
            systemImage: "moon.stars",
            focus: .twilight
        ),
        OrlojGuideItem(
            id: .lightAndShadow,
            section: .light,
            title: "Light and shadow",
            subtitle: "Sunlight on the clock face",
            shortDescription: "The dial is lit as if it hung on Prague's Old Town Hall: on a wall facing the equator, under the real Sun for this place and time.",
            longDescription: "Hands, the Sun, the Moon and the zodiac ring stand in front of the plate and cast shadows. A high summer Sun throws long shadows straight down; a low winter Sun short ones. In the morning they fall to one side and in the afternoon to the other. When the Sun is behind the wall or below the horizon, only soft skylight remains.",
            readingSteps: [
                "Look at the direction of the hands' shadows: they point away from the Sun.",
                "Long shadows mean the Sun is high or off to the side and grazes the wall; short ones mean it shines almost straight at the face.",
                "No crisp shadows means the face is in shade or it is night."
            ],
            pragueNote: "The Orloj is on the town hall's south wall, so the face is in direct sun from morning to late afternoon and in shade on summer evenings, when the Sun sets in the north-west.",
            targetLayers: [.castShadows, .sunMarker, .sunHand, .moonMarker],
            currentValue: .light,
            calloutLabel: "Shadows follow the real Sun",
            systemImage: "sun.and.horizon",
            focus: .sun
        )
    ]

    static func items(in section: OrlojGuideSection) -> [OrlojGuideItem] {
        items.filter { $0.section == section }
    }

    static func item(for id: OrlojGuideTopicID?) -> OrlojGuideItem? {
        guard let id else {
            return nil
        }

        return items.first { $0.id == id }
    }

    /// The topic listed before or after `id` in the guide, for stepping through it.
    static func neighbour(of id: OrlojGuideTopicID, offset: Int) -> OrlojGuideItem? {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        let target = index + offset
        guard items.indices.contains(target) else {
            return nil
        }
        return items[target]
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
        case .earth:
            return "Sky for \(readout.locationName) · \(readout.coordinates)"
        case .light:
            return readout.lighting
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
        case .earth:
            return "Sky for \(state.location.name)"
        case .light:
            return state.dialLighting.summary
        }
    }
}
