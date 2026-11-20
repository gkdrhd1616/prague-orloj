//
//  OrlojAstronomyReadout.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import Foundation

struct OrlojAstronomyReadout {
    let isPragueMechanism: Bool
    let dialTime: String
    let dialTimeZone: String
    let dialTimeBasis: String
    let localTime: String
    let localDate: String
    let locationName: String
    let timeZone: String
    let coordinates: String
    let sunrise: String
    let sunset: String
    let dawn: String
    let dusk: String
    let dawnDusk: String
    let nightInterval: String
    let skyPhase: String
    let sunAltitude: String
    let solarDeclination: String
    let solarTropicPosition: String
    let solarEclipticLongitude: String
    let zodiacDegree: String
    let siderealTime: String
    let equationOfTime: String
    let zodiacName: String
    let zodiacReading: String
    let moonPhase: String
    let moonIllumination: String
    let moonAge: String
    let moonRevolution: String
    let moonPhaseAngle: String
    let oldCzechHour: String
    let ancientDayBoundary: String
    let babylonianHour: String
    let daylightProgress: String
    let lighting: String

    init(state: OrlojClockState) {
        isPragueMechanism = state.isPragueMechanism
        dialTime = state.dialTimeString
        dialTimeZone = state.dialTimeZoneLabel
        dialTimeBasis = state.dialTimeBasisDescription
        localTime = state.localTimeString
        localDate = state.localDateString
        locationName = state.location.name
        timeZone = state.timeZoneAbbreviation
        coordinates = "\(state.location.coordinates.latitudeLabel), \(state.location.coordinates.longitudeLabel)"
        sunrise = state.sunriseTimeString
        sunset = state.sunsetTimeString
        dawn = state.dawnTimeString
        dusk = state.duskTimeString
        dawnDusk = state.twilightIntervalLabel
        nightInterval = state.nightIntervalLabel
        skyPhase = state.skyPhaseLabel
        sunAltitude = state.sunAltitudeLabel
        solarDeclination = state.solarDeclinationLabel
        solarTropicPosition = state.solarTropicPositionLabel
        solarEclipticLongitude = state.solarEclipticLongitudeLabel
        zodiacDegree = state.zodiacDegreeLabel
        siderealTime = state.siderealTimeString
        equationOfTime = state.equationOfTimeLabel
        zodiacName = state.zodiacSign.name
        zodiacReading = state.zodiacSign.reading
        moonPhase = state.lunar.phaseName
        moonIllumination = state.moonIlluminationLabel
        moonAge = state.moonAgeLabel
        moonRevolution = state.moonRevolutionLabel
        moonPhaseAngle = state.moonPhaseAngleLabel
        oldCzechHour = state.oldCzechHourLabel
        ancientDayBoundary = state.ancientDayBoundaryLabel
        babylonianHour = state.babylonianHourLabel
        daylightProgress = state.daylightProgressLabel
        lighting = state.dialLighting.summary
    }

    var primaryMetrics: [OrlojReadoutMetric] {
        var metrics: [OrlojReadoutMetric] = []
        metrics.append(OrlojReadoutMetric(
            systemImage: "clock",
            title: isPragueMechanism ? "Dial time" : "Apparent solar time",
            value: "\(dialTime) \(dialTimeZone)",
            detail: dialTimeBasis,
            guideTopic: .romanTime,
            prominence: .primary
        ))
        metrics += [
            OrlojReadoutMetric(
                systemImage: "clock",
                title: "Local time",
                value: localTime,
                detail: "\(locationName) \(timeZone)",
                guideTopic: nil,
                prominence: .primary
            ),
            OrlojReadoutMetric(
                systemImage: "sun.horizon",
                title: "Sunrise / Sunset",
                value: "\(sunrise) / \(sunset)",
                detail: "visible day",
                guideTopic: .horizon,
                prominence: .primary
            ),
            OrlojReadoutMetric(
                systemImage: "moon.stars",
                title: "Twilight",
                value: dawnDusk,
                detail: skyPhase,
                guideTopic: .twilight,
                prominence: .secondary
            )
        ]
        return metrics
    }

    var astronomyMetrics: [OrlojReadoutMetric] {
        [
            OrlojReadoutMetric(systemImage: "sun.max", title: "Sun", value: sunAltitude, detail: "\(solarDeclination) dec", guideTopic: .sun, prominence: .primary),
            OrlojReadoutMetric(systemImage: "circle.dashed", title: "Ecliptic", value: solarEclipticLongitude, detail: zodiacDegree, guideTopic: .zodiacRing, prominence: .secondary),
            OrlojReadoutMetric(systemImage: "scope", title: "Sidereal", value: siderealTime, detail: "local star time", guideTopic: .siderealAries, prominence: .secondary),
            OrlojReadoutMetric(systemImage: "moonphase.waxing.gibbous", title: "Moon", value: moonPhase, detail: "\(moonIllumination) lit · \(moonPhaseAngle)", guideTopic: .moon, prominence: .primary),
            OrlojReadoutMetric(systemImage: "clock", title: "Old Czech time", value: oldCzechHour, detail: ancientDayBoundary, guideTopic: .oldCzechTime, prominence: .primary),
            OrlojReadoutMetric(systemImage: "rays", title: "Unequal / Babylonian", value: babylonianHour, detail: daylightProgress, guideTopic: .unequalHours, prominence: .secondary),
            OrlojReadoutMetric(systemImage: "plus.forwardslash.minus", title: "Mean solar", value: equationOfTime, detail: "equation of time", guideTopic: .romanTime, prominence: .secondary),
            OrlojReadoutMetric(systemImage: "location", title: "Coordinates", value: coordinates, detail: timeZone, guideTopic: nil, prominence: .secondary)
        ]
    }
}

enum OrlojReadoutProminence: Equatable {
    case primary
    case secondary
}

struct OrlojReadoutMetric: Identifiable {
    var id: String {
        "\(title)-\(value)-\(detail)"
    }

    let systemImage: String
    let title: String
    let value: String
    let detail: String
    let guideTopic: OrlojGuideTopicID?
    let prominence: OrlojReadoutProminence
}
