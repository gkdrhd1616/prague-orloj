//
//  OrlojClockModel.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import Foundation

struct OrlojClockState {
    let date: Date
    let location: OrlojClockLocation
    let localComponents: DateComponents
    let localDecimalHour: Double
    let dayProgress: Double
    let dawnMinutes: Double
    let sunriseMinutes: Double
    let sunsetMinutes: Double
    let duskMinutes: Double
    let daylightWindow: OrlojSolarWindow
    let twilightWindow: OrlojSolarWindow
    let daylightProgress: Double
    let babylonianHour: Int?
    let oldCzechHour: Int
    let solar: SolarPosition
    let sunriseSolarHourAngleDegrees: Double?
    let sunsetSolarHourAngleDegrees: Double?
    let lunar: LunarState
    let zodiacSign: ZodiacSign
    let unequalHourBoundaries: [[OrlojProjectionPoint]]

    var isPragueMechanism: Bool {
        location.id == OrlojClockLocation.prague.id
    }

    private var dialOffsetMinutes: Double {
        isPragueMechanism ? 60 - Double(location.timeZone.secondsFromGMT(for: date)) / 60 : 0
    }

    var dialDecimalHour: Double {
        isPragueMechanism
            ? (localDecimalHour * 60 + dialOffsetMinutes).wrappedMinutes / 60
            : solar.apparentSolarMinutes / 60
    }

    var dialSunriseMinutes: Double {
        if isPragueMechanism, let sunriseDate = daylightWindow.startDate {
            return (sunriseDate.timeIntervalSince1970 / 60 + 60).wrappedMinutes
        }
        if !isPragueMechanism, let sunriseSolarHourAngleDegrees {
            return OrlojCalculator.normalizedDegrees(sunriseSolarHourAngleDegrees + 180) * 4
        }
        return (sunriseMinutes + dialOffsetMinutes).wrappedMinutes
    }

    var dialSunsetMinutes: Double {
        if isPragueMechanism, let sunsetDate = daylightWindow.endDate {
            return (sunsetDate.timeIntervalSince1970 / 60 + 60).wrappedMinutes
        }
        if !isPragueMechanism, let sunsetSolarHourAngleDegrees {
            return OrlojCalculator.normalizedDegrees(sunsetSolarHourAngleDegrees + 180) * 4
        }
        return (sunsetMinutes + dialOffsetMinutes).wrappedMinutes
    }

    var dialTimeString: String {
        let minutes = Int(dialDecimalHour * 60 + 1e-8).positiveModulo(1440)
        return String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    var dialTimeZoneLabel: String {
        isPragueMechanism ? "CET" : "solar"
    }

    var dialTimeBasisDescription: String {
        isPragueMechanism
            ? "Prague dial · CET (UTC+1), without daylight saving · idealized reconstruction"
            : "Apparent solar time at the selected coordinates; local civil time is shown separately"
    }

    var civilAngleDegrees: Double {
        OrlojCalculator.orlojAngle(forLocalHour: dialDecimalHour)
    }

    var sunriseAngleDegrees: Double {
        OrlojCalculator.orlojAngle(forLocalHour: dialSunriseMinutes / 60)
    }

    var sunsetAngleDegrees: Double {
        OrlojCalculator.orlojAngle(forLocalHour: dialSunsetMinutes / 60)
    }

    var moonAngleDegrees: Double {
        OrlojCalculator.orlojAngle(forLocalHour: lunar.rightAscensionDegrees / 15)
    }

    var siderealAngleDegrees: Double {
        OrlojCalculator.orlojAngle(forLocalHour: siderealDecimalHour)
    }

    var siderealDecimalHour: Double {
        solar.localSiderealTimeDegrees / 15
    }

    var zodiacRotationDegrees: Double {
        OrlojCalculator.normalizedDegrees(90 - solar.eclipticLongitudeDegrees)
    }

    var zodiacDegreeInSign: Double {
        OrlojCalculator.normalizedDegrees(solar.eclipticLongitudeDegrees)
            .truncatingRemainder(dividingBy: 30)
    }

    var solarDeclinationRatio: Double {
        (solar.declinationDegrees / solar.obliquityDegrees).clamped(to: -1...1)
    }

    var sunProjection: OrlojProjectionPoint {
        OrlojProjection.projectEquatorial(
            rightAscensionDegrees: solar.rightAscensionDegrees,
            declinationDegrees: solar.declinationDegrees,
            localSiderealTimeDegrees: solar.localSiderealTimeDegrees
        )
    }

    var moonProjection: OrlojProjectionPoint {
        OrlojProjection.projectEquatorial(
            rightAscensionDegrees: lunar.rightAscensionDegrees,
            declinationDegrees: lunar.declinationDegrees,
            localSiderealTimeDegrees: solar.localSiderealTimeDegrees
        )
    }

    var dialSolarLongitudeDegrees: Double {
        guard isPragueMechanism else {
            return solar.eclipticLongitudeDegrees
        }
        // A ray at hour angle H has right ascension LST - H. On the
        // ecliptic, tan(RA) = cos(obliquity) * tan(longitude).
        let rightAscension = OrlojCalculator.degreesToRadians(solar.localSiderealTimeDegrees - civilAngleDegrees)
        let obliquity = OrlojCalculator.degreesToRadians(solar.obliquityDegrees)
        return OrlojCalculator.normalizedDegrees(OrlojCalculator.radiansToDegrees(atan2(
            sin(rightAscension) / cos(obliquity),
            cos(rightAscension)
        )))
    }

    var dialZodiacSign: ZodiacSign {
        OrlojCalculator.zodiacSign(for: dialSolarLongitudeDegrees)
    }

    var dialSunProjection: OrlojProjectionPoint {
        guard isPragueMechanism else { return sunProjection }
        // The idealized mechanism keeps the Sun on both the uniform CET
        // hand and the rotating ecliptic. Real-sky values remain in solar.
        return OrlojProjection.projectEcliptic(
            longitudeDegrees: dialSolarLongitudeDegrees,
            obliquityDegrees: solar.obliquityDegrees,
            localSiderealTimeDegrees: solar.localSiderealTimeDegrees
        )
    }

    var dialMoonProjection: OrlojProjectionPoint {
        guard isPragueMechanism else { return moonProjection }
        return OrlojProjection.projectEcliptic(
            longitudeDegrees: lunar.eclipticLongitudeDegrees,
            latitudeDegrees: 0,
            obliquityDegrees: solar.obliquityDegrees,
            localSiderealTimeDegrees: solar.localSiderealTimeDegrees
        )
    }

    var ariesProjection: OrlojProjectionPoint {
        OrlojProjection.projectEcliptic(
            longitudeDegrees: 0,
            latitudeDegrees: 0,
            obliquityDegrees: solar.obliquityDegrees,
            localSiderealTimeDegrees: solar.localSiderealTimeDegrees
        )
    }

    var skyPhaseLabel: String {
        if solar.altitudeDegrees >= 0 {
            return "Day"
        }
        if solar.altitudeDegrees >= -18 {
            return "Twilight"
        }

        return "Night"
    }

    var localTimeString: String {
        formattedLocalDate(dateStyle: .none, timeStyle: .short)
    }

    var localDateString: String {
        formattedLocalDate(dateStyle: .medium, timeStyle: .short)
    }

    var timeZoneAbbreviation: String {
        location.timeZone.abbreviation(for: date) ?? location.timeZone.identifier
    }

    var sunAltitudeLabel: String {
        "\(Int(solar.altitudeDegrees.rounded())) deg"
    }

    var solarDeclinationLabel: String {
        signedDegreesLabel(solar.declinationDegrees)
    }

    var solarTropicPositionLabel: String {
        let percent = Int((abs(solarDeclinationRatio) * 100).rounded())
        if abs(solarDeclinationRatio) < 0.04 {
            return "Equator"
        }

        return solarDeclinationRatio > 0 ? "Cancer \(percent)%" : "Capricorn \(percent)%"
    }

    var solarEclipticLongitudeLabel: String {
        String(format: "%.1f deg", OrlojCalculator.normalizedDegrees(solar.eclipticLongitudeDegrees))
    }

    var zodiacDegreeLabel: String {
        String(format: "%@ %.1f deg", zodiacSign.name, zodiacDegreeInSign)
    }

    var siderealTimeString: String {
        formattedClockHours(siderealDecimalHour)
    }

    var equationOfTimeLabel: String {
        String(format: "%+.0f min", solar.equationOfTimeMinutes)
    }

    var sunriseTimeString: String {
        formattedLocalMinutes(sunriseMinutes)
    }

    var sunsetTimeString: String {
        formattedLocalMinutes(sunsetMinutes)
    }

    var dawnTimeString: String {
        guard twilightWindow.kind == .normal else {
            return "--"
        }

        return formattedLocalMinutes(dawnMinutes)
    }

    var duskTimeString: String {
        guard twilightWindow.kind == .normal else {
            return "--"
        }

        return formattedLocalMinutes(duskMinutes)
    }

    var daylightIntervalLabel: String {
        "\(sunriseTimeString)-\(sunsetTimeString)"
    }

    var nightIntervalLabel: String {
        switch twilightWindow.kind {
        case .normal:
            break
        case .alwaysAbove:
            return "No astronomical night"
        case .alwaysBelow:
            return "No twilight crossing"
        }

        return "\(duskTimeString)-\(dawnTimeString)"
    }

    var twilightIntervalLabel: String {
        switch twilightWindow.kind {
        case .normal:
            break
        case .alwaysAbove:
            return "No astronomical night"
        case .alwaysBelow:
            return "No twilight crossing"
        }

        return "\(dawnTimeString) / \(duskTimeString)"
    }

    var daylightProgressLabel: String {
        "\(Int((daylightProgress * 100).rounded()))%"
    }

    var moonIlluminationLabel: String {
        "\(Int((lunar.illumination * 100).rounded()))%"
    }

    var moonAgeLabel: String {
        "\(Int(lunar.ageDays.rounded()))d"
    }

    var moonRevolutionLabel: String {
        String(format: "%.2f rev", lunar.revolutionFraction)
    }

    var moonPhaseAngleLabel: String {
        String(format: "%.0f deg", lunar.phaseAngleDegrees)
    }

    var ancientDayBoundaryLabel: String {
        isPragueMechanism
            ? "Starts \(formattedLocalMinutes(dialSunsetMinutes)) CET"
            : "Starts \(formattedLocalMinutes(dialSunsetMinutes)) solar"
    }

    var babylonianHourLabel: String {
        guard let babylonianHour else {
            return "Night"
        }

        return "Hour \(babylonianHour)"
    }

    var oldCzechHourLabel: String {
        "Hour \(oldCzechHour)"
    }

    private func formattedLocalDate(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = location.timeZone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }

    private func formattedLocalMinutes(_ minutes: Double) -> String {
        let wrapped = Int(minutes.rounded()).positiveModulo(1440)
        return String(format: "%02d:%02d", wrapped / 60, wrapped % 60)
    }

    private func formattedClockHours(_ hours: Double) -> String {
        let wrappedMinutes = Int((hours * 60).rounded()).positiveModulo(1440)
        return String(format: "%02d:%02d", wrappedMinutes / 60, wrappedMinutes % 60)
    }

    private func signedDegreesLabel(_ degrees: Double) -> String {
        if abs(degrees) < 0.05 {
            return "0.0 deg"
        }

        let hemisphere = degrees > 0 ? "N" : "S"
        return String(format: "%@ %.1f deg", hemisphere, abs(degrees))
    }
}

struct OrlojCoordinates: Equatable {
    static let seoul = OrlojCoordinates(latitude: 37.566, longitude: 126.978)
    static let prague = OrlojCoordinates(latitude: 50.087, longitude: 14.421)

    var latitude: Double
    var longitude: Double

    var normalized: OrlojCoordinates {
        OrlojCoordinates(
            latitude: latitude.clamped(to: -66...66),
            longitude: longitude.clamped(to: -180...180)
        )
    }

    var latitudeLabel: String {
        String(format: "%.3f", latitude)
    }

    var longitudeLabel: String {
        String(format: "%.3f", longitude)
    }
}

struct OrlojClockLocation: Equatable, Identifiable {
    static let seoul = OrlojClockLocation(
        id: "seoul",
        name: "Seoul",
        detail: "Korean standard time",
        coordinates: .seoul,
        timeZone: TimeZone(identifier: "Asia/Seoul") ?? .current
    )
    static let prague = OrlojClockLocation(
        id: "prague",
        name: "Prague",
        detail: "Original Orloj mood",
        coordinates: .prague,
        timeZone: TimeZone(identifier: "Europe/Prague") ?? .current
    )

    static let presets: [OrlojClockLocation] = [.prague, .seoul]

    let id: String
    var name: String
    var detail: String
    var coordinates: OrlojCoordinates
    var timeZone: TimeZone

    static func detected(
        name: String,
        coordinates: OrlojCoordinates,
        timeZone: TimeZone
    ) -> OrlojClockLocation {
        OrlojClockLocation(
            id: "detected",
            name: name,
            detail: "Detected from GPS",
            coordinates: coordinates,
            timeZone: timeZone
        )
    }

    static func custom(
        name: String,
        coordinates: OrlojCoordinates,
        timeZone: TimeZone
    ) -> OrlojClockLocation {
        OrlojClockLocation(
            id: "custom",
            name: name,
            detail: "Manual settings",
            coordinates: coordinates,
            timeZone: timeZone
        )
    }

    static func == (lhs: OrlojClockLocation, rhs: OrlojClockLocation) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.detail == rhs.detail
            && lhs.coordinates == rhs.coordinates
            && lhs.timeZone.identifier == rhs.timeZone.identifier
    }
}

struct SolarPosition {
    let altitudeDegrees: Double
    let azimuthDegrees: Double
    let eclipticLongitudeDegrees: Double
    let declinationDegrees: Double
    let rightAscensionDegrees: Double
    let localSiderealTimeDegrees: Double
    let obliquityDegrees: Double
    let equationOfTimeMinutes: Double

    var hourAngleDegrees: Double {
        OrlojCalculator.normalizedDegrees(localSiderealTimeDegrees - rightAscensionDegrees)
    }

    var apparentSolarMinutes: Double {
        OrlojCalculator.normalizedDegrees(hourAngleDegrees + 180) * 4
    }
}

struct LunarState {
    let ageDays: Double
    let phaseFraction: Double
    let revolutionFraction: Double
    let phaseAngleDegrees: Double
    let eclipticLongitudeDegrees: Double
    let eclipticLatitudeDegrees: Double
    let declinationDegrees: Double
    let rightAscensionDegrees: Double
    let illumination: Double
    let phaseName: String
}

struct OrlojEquatorialCoordinate {
    let rightAscensionDegrees: Double
    let declinationDegrees: Double
}

struct OrlojProjectionPoint: Equatable {
    let x: Double
    let y: Double

    var radius: Double {
        hypot(x, y)
    }
}

struct OrlojProjectionCircle: Equatable {
    let centerY: Double
    let radius: Double
    let lowerAltitudeIsInside: Bool

    var center: OrlojProjectionPoint {
        OrlojProjectionPoint(x: 0, y: centerY)
    }
}

enum OrlojProjectionBoundary: Equatable {
    case circle(OrlojProjectionCircle)
    case lineY(Double)
}

enum OrlojSolarWindowKind: Equatable {
    case normal
    case alwaysAbove
    case alwaysBelow
}

struct OrlojSolarWindow: Equatable {
    let kind: OrlojSolarWindowKind
    let startMinutes: Double
    let endMinutes: Double
    let startDate: Date?
    let endDate: Date?

    var sunrise: Double {
        startMinutes
    }

    var sunset: Double {
        endMinutes
    }

    static func normal(startMinutes: Double, endMinutes: Double, startDate: Date?, endDate: Date?) -> OrlojSolarWindow {
        OrlojSolarWindow(kind: .normal, startMinutes: startMinutes, endMinutes: endMinutes, startDate: startDate, endDate: endDate)
    }

    static let alwaysAbove = OrlojSolarWindow(kind: .alwaysAbove, startMinutes: 0, endMinutes: 1440, startDate: nil, endDate: nil)
    static let alwaysBelow = OrlojSolarWindow(kind: .alwaysBelow, startMinutes: 0, endMinutes: 0, startDate: nil, endDate: nil)
}

enum OrlojProjection {
    private static let singularityEpsilon = 1e-8

    static func projectEquatorial(
        rightAscensionDegrees: Double,
        declinationDegrees: Double,
        localSiderealTimeDegrees: Double
    ) -> OrlojProjectionPoint {
        let rightAscension = OrlojCalculator.degreesToRadians(rightAscensionDegrees)
        let declination = OrlojCalculator.degreesToRadians(declinationDegrees)
        let localSiderealTime = OrlojCalculator.degreesToRadians(localSiderealTimeDegrees)
        let hourAngle = normalizeRadiansToPi(localSiderealTime - rightAscension)
        let rho = tan(.pi / 4 + declination / 2)

        return OrlojProjectionPoint(
            x: rho * sin(hourAngle),
            y: rho * cos(hourAngle)
        )
    }

    static func eclipticToEquatorial(
        longitudeDegrees: Double,
        latitudeDegrees: Double = 0,
        obliquityDegrees: Double
    ) -> OrlojEquatorialCoordinate {
        let longitude = OrlojCalculator.degreesToRadians(longitudeDegrees)
        let latitude = OrlojCalculator.degreesToRadians(latitudeDegrees)
        let obliquity = OrlojCalculator.degreesToRadians(obliquityDegrees)
        let sinDeclination = sin(latitude) * cos(obliquity) + cos(latitude) * sin(obliquity) * sin(longitude)
        let declination = asin(sinDeclination)
        let y = sin(longitude) * cos(obliquity) - tan(latitude) * sin(obliquity)
        let rightAscension = atan2(y, cos(longitude))

        return OrlojEquatorialCoordinate(
            rightAscensionDegrees: OrlojCalculator.normalizedDegrees(OrlojCalculator.radiansToDegrees(rightAscension)),
            declinationDegrees: OrlojCalculator.radiansToDegrees(declination)
        )
    }

    static func projectEcliptic(
        longitudeDegrees: Double,
        latitudeDegrees: Double = 0,
        obliquityDegrees: Double,
        localSiderealTimeDegrees: Double
    ) -> OrlojProjectionPoint {
        let equatorial = eclipticToEquatorial(
            longitudeDegrees: longitudeDegrees,
            latitudeDegrees: latitudeDegrees,
            obliquityDegrees: obliquityDegrees
        )

        return projectEquatorial(
            rightAscensionDegrees: equatorial.rightAscensionDegrees,
            declinationDegrees: equatorial.declinationDegrees,
            localSiderealTimeDegrees: localSiderealTimeDegrees
        )
    }

    static func constantAltitudeCircle(latitudeDegrees: Double, altitudeDegrees: Double) -> OrlojProjectionCircle? {
        guard case .circle(let circle) = constantAltitudeBoundary(
            latitudeDegrees: latitudeDegrees,
            altitudeDegrees: altitudeDegrees
        ) else {
            return nil
        }
        return circle
    }

    static func constantAltitudeBoundary(latitudeDegrees: Double, altitudeDegrees: Double) -> OrlojProjectionBoundary {
        let latitude = OrlojCalculator.degreesToRadians(latitudeDegrees)
        let altitude = OrlojCalculator.degreesToRadians(altitudeDegrees)
        let denominator = sin(latitude) - sin(altitude)
        if abs(denominator) < singularityEpsilon {
            let latitudeCosine = cos(latitude)
            guard abs(latitudeCosine) >= singularityEpsilon else {
                return .lineY(0)
            }

            let lineY = (sin(latitude) + sin(altitude)) / (2 * latitudeCosine)
            return .lineY(lineY)
        }

        let a = cos(latitude) / denominator
        let b = (sin(latitude) + sin(altitude)) / denominator

        return .circle(OrlojProjectionCircle(
            centerY: -a,
            radius: sqrt(max(0, a * a + b)),
            // Dividing the altitude inequality by this denominator reverses its
            // sense south of the boundary's latitude (including the -18° band).
            lowerAltitudeIsInside: denominator > 0
        ))
    }

    static func circleEquationValue(point: OrlojProjectionPoint, circle: OrlojProjectionCircle) -> Double {
        let a = -circle.centerY
        let b = circle.radius * circle.radius - a * a
        return point.x * point.x + point.y * point.y + 2 * a * point.y - b
    }

    static func normalizeRadiansToPi(_ radians: Double) -> Double {
        var value = radians.truncatingRemainder(dividingBy: 2 * .pi)
        if value <= -.pi {
            value += 2 * .pi
        } else if value > .pi {
            value -= 2 * .pi
        }
        return value
    }
}

struct ZodiacSign: Identifiable {
    var id: String {
        name
    }

    let name: String
    let symbol: String
    let assetName: String
    let reading: String

    static let all: [ZodiacSign] = [
        ZodiacSign(
            name: "Aries",
            symbol: "♈",
            assetName: "zodiac_aries",
            reading: "태양이 황도의 Aries 구간에 있습니다. 시작, 추진력, 봄의 불씨를 상징합니다."
        ),
        ZodiacSign(
            name: "Taurus",
            symbol: "♉",
            assetName: "zodiac_taurus",
            reading: "태양이 황도의 Taurus 구간에 있습니다. 감각, 지속성, 대지의 리듬을 상징합니다."
        ),
        ZodiacSign(
            name: "Gemini",
            symbol: "♊",
            assetName: "zodiac_gemini",
            reading: "태양이 황도의 Gemini 구간에 있습니다. 언어, 교류, 둘 사이를 잇는 움직임을 상징합니다."
        ),
        ZodiacSign(
            name: "Cancer",
            symbol: "♋",
            assetName: "zodiac_cancer",
            reading: "태양이 황도의 Cancer 구간에 있습니다. 보호, 기억, 안쪽으로 흐르는 물성을 상징합니다."
        ),
        ZodiacSign(
            name: "Leo",
            symbol: "♌",
            assetName: "zodiac_leo",
            reading: "태양이 황도의 Leo 구간에 있습니다. 중심성, 창조성, 밝게 드러나는 힘을 상징합니다."
        ),
        ZodiacSign(
            name: "Virgo",
            symbol: "♍",
            assetName: "zodiac_virgo",
            reading: "태양이 황도의 Virgo 구간에 있습니다. 정리, 돌봄, 세밀한 질서를 상징합니다."
        ),
        ZodiacSign(
            name: "Libra",
            symbol: "♎",
            assetName: "zodiac_libra",
            reading: "태양이 황도의 Libra 구간에 있습니다. 균형, 관계, 저울질하는 감각을 상징합니다."
        ),
        ZodiacSign(
            name: "Scorpio",
            symbol: "♏",
            assetName: "zodiac_scorpio",
            reading: "태양이 황도의 Scorpio 구간에 있습니다. 깊이, 변형, 숨은 힘을 상징합니다."
        ),
        ZodiacSign(
            name: "Sagittarius",
            symbol: "♐",
            assetName: "zodiac_sagittarius",
            reading: "태양이 황도의 Sagittarius 구간에 있습니다. 탐구, 방향성, 멀리 겨누는 시야를 상징합니다."
        ),
        ZodiacSign(
            name: "Capricorn",
            symbol: "♑",
            assetName: "zodiac_capricorn",
            reading: "태양이 황도의 Capricorn 구간에 있습니다. 구조, 책임, 산을 오르는 시간을 상징합니다."
        ),
        ZodiacSign(
            name: "Aquarius",
            symbol: "♒",
            assetName: "zodiac_aquarius",
            reading: "태양이 황도의 Aquarius 구간에 있습니다. 흐름, 갱신, 공동체적 시야를 상징합니다."
        ),
        ZodiacSign(
            name: "Pisces",
            symbol: "♓",
            assetName: "zodiac_pisces",
            reading: "태양이 황도의 Pisces 구간에 있습니다. 상상, 공감, 경계를 녹이는 물결을 상징합니다."
        )
    ]
}

final class OrlojUnequalHourCurveCache {
    static let shared = OrlojUnequalHourCurveCache()

    private struct Key: Hashable {
        let year: Int
        let latitude: Int
        let longitude: Int
        let timeZoneIdentifier: String
    }

    private var storage: [Key: [[OrlojProjectionPoint]]] = [:]
    private let lock = NSLock()

    func curves(year: Int, location: OrlojClockLocation) -> [[OrlojProjectionPoint]] {
        let normalizedLocation = OrlojClockLocation(
            id: location.id,
            name: location.name,
            detail: location.detail,
            coordinates: location.coordinates.normalized,
            timeZone: location.timeZone
        )
        let key = Key(
            year: year,
            latitude: Int((normalizedLocation.coordinates.latitude * 1000).rounded()),
            longitude: Int((normalizedLocation.coordinates.longitude * 1000).rounded()),
            timeZoneIdentifier: normalizedLocation.timeZone.identifier
        )

        lock.lock()
        if let cached = storage[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let curves = (1...11).map { boundary in
            OrlojCalculator.unequalHourBoundarySamples(
                boundary: boundary,
                year: year,
                location: normalizedLocation,
                stepDays: 3
            )
        }

        lock.lock()
        if let cached = storage[key] {
            lock.unlock()
            return cached
        }
        storage[key] = curves
        lock.unlock()
        return curves
    }
}

enum OrlojCalculator {
    private static let synodicMonth = 29.530588853

    static func state(for date: Date, location: OrlojClockLocation = .prague) -> OrlojClockState {
        let normalizedLocation = OrlojClockLocation(
            id: location.id,
            name: location.name,
            detail: location.detail,
            coordinates: location.coordinates.normalized,
            timeZone: location.timeZone
        )
        return state(for: date, resolvedLocation: normalizedLocation)
    }

    static func state(
        for date: Date,
        coordinates: OrlojCoordinates,
        timeZone: TimeZone = OrlojClockLocation.prague.timeZone
    ) -> OrlojClockState {
        state(
            for: date,
            resolvedLocation: .custom(
                name: "Custom",
                coordinates: coordinates.normalized,
                timeZone: timeZone
            )
        )
    }

    private static func state(for date: Date, resolvedLocation location: OrlojClockLocation) -> OrlojClockState {
        let coordinates = location.coordinates
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .timeZone],
            from: date
        )
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        let decimalHour = hour + minute / 60 + second / 3600
        let dayProgress = decimalHour / 24

        let solarWindow = daylightWindow(
            for: date,
            calendar: calendar,
            coordinates: coordinates,
            timeZone: location.timeZone
        )
        let twilightWindow = daylightWindow(
            for: date,
            calendar: calendar,
            coordinates: coordinates,
            timeZone: location.timeZone,
            zenithDegrees: 108
        )
        let localMinutes = decimalHour * 60
        let daylightDuration = daylightDuration(for: solarWindow)
        let minutesSinceSunrise = solarWindow.startDate.map { date.timeIntervalSince($0) / 60 }
            ?? minutesBetween(solarWindow.sunrise, localMinutes)
        let isDaylight = solarWindow.kind == .normal && minutesSinceSunrise >= 0 && minutesSinceSunrise <= daylightDuration
        let daylightProgress = isDaylight
            ? (minutesSinceSunrise / daylightDuration).clamped(to: 0...1)
            : 0
        let babylonianHour = isDaylight
            ? min(12, max(1, Int(floor(daylightProgress * 12)) + 1))
            : nil
        let julianDay = julianDay(from: date)
        let solar = solarPosition(julianDay: julianDay, coordinates: coordinates)
        let sunriseSolar = solarWindow.startDate.map {
            solarPosition(julianDay: self.julianDay(from: $0), coordinates: coordinates)
        }
        let sunsetSolar = solarWindow.endDate.map {
            solarPosition(julianDay: self.julianDay(from: $0), coordinates: coordinates)
        }
        let isPragueMechanism = location.id == OrlojClockLocation.prague.id
        let cetOffsetMinutes = 60 - Double(location.timeZone.secondsFromGMT(for: date)) / 60
        let sunsetDialMinutes = isPragueMechanism
            ? solarWindow.endDate.map { ($0.timeIntervalSince1970 / 60 + 60).wrappedMinutes }
            : sunsetSolar?.apparentSolarMinutes
        let oldCzechHour = oldCzechHour(
            localMinutes: isPragueMechanism ? localMinutes + cetOffsetMinutes : solar.apparentSolarMinutes,
            sunsetMinutes: sunsetDialMinutes ?? solarWindow.sunset
        )
        let lunar = lunarState(
            julianDay: julianDay,
            solarEclipticLongitude: solar.eclipticLongitudeDegrees,
            obliquityDegrees: solar.obliquityDegrees
        )
        let zodiacSign = zodiacSign(for: solar.eclipticLongitudeDegrees)
        let year = components.year ?? 2026
        let unequalHourBoundaries = OrlojUnequalHourCurveCache.shared.curves(year: year, location: location)

        return OrlojClockState(
            date: date,
            location: location,
            localComponents: components,
            localDecimalHour: decimalHour,
            dayProgress: dayProgress,
            dawnMinutes: twilightWindow.sunrise,
            sunriseMinutes: solarWindow.sunrise,
            sunsetMinutes: solarWindow.sunset,
            duskMinutes: twilightWindow.sunset,
            daylightWindow: solarWindow,
            twilightWindow: twilightWindow,
            daylightProgress: daylightProgress,
            babylonianHour: babylonianHour,
            oldCzechHour: oldCzechHour,
            solar: solar,
            sunriseSolarHourAngleDegrees: sunriseSolar?.hourAngleDegrees,
            sunsetSolarHourAngleDegrees: sunsetSolar?.hourAngleDegrees,
            lunar: lunar,
            zodiacSign: zodiacSign,
            unequalHourBoundaries: unequalHourBoundaries
        )
    }

    static func orlojAngle(forLocalHour hour: Double) -> Double {
        normalizedDegrees((hour - 12) / 24 * 360)
    }

    static func oldCzechHour(localMinutes: Double, sunsetMinutes: Double) -> Int {
        let elapsed = minutesBetween(sunsetMinutes, localMinutes)
        if elapsed < .ulpOfOne {
            return 24
        }

        let hour = Int(ceil(elapsed / 60))
        return min(24, max(1, hour))
    }

    static func zodiacSign(for eclipticLongitude: Double) -> ZodiacSign {
        let index = Int(floor(normalizedDegrees(eclipticLongitude) / 30)) % ZodiacSign.all.count
        return ZodiacSign.all[index]
    }

    static func normalizedDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value < 0 {
            value += 360
        }
        return value
    }

    static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }

    static func unequalHourLabelPositions(latitudeDegrees: Double) -> [OrlojProjectionPoint] {
        let latitude = degreesToRadians(latitudeDegrees.clamped(to: -66...66))
        // A fixed northern-solstice parallel puts the inscriptions near the
        // outer daylight field, independent of the displayed date and time.
        var declination = degreesToRadians(23.439291)
        if latitude < 0 {
            // At far-southern latitudes that parallel has a very short visible
            // arc. Move inward until at least six ordinary hours are visible.
            declination = min(declination, atan(cos(.pi / 4) / -tan(latitude)))
        }
        let sunriseHourAngle = acos((-tan(latitude) * tan(declination)).clamped(to: -1...1))
        return (0..<12).map { index in
            let daylightFraction = (Double(index) + 0.5) / 12
            let hourAngle = (2 * daylightFraction - 1) * sunriseHourAngle
            return OrlojProjection.projectEquatorial(
                rightAscensionDegrees: 0,
                declinationDegrees: radiansToDegrees(declination),
                localSiderealTimeDegrees: radiansToDegrees(hourAngle)
            )
        }
    }

    static func unequalHourBoundarySamples(
        boundary: Int,
        year: Int,
        location: OrlojClockLocation,
        stepDays: Int = 3
    ) -> [OrlojProjectionPoint] {
        let boundary = boundary.clamped(to: 1...11)
        let stepDays = max(1, stepDays)
        let normalizedLocation = OrlojClockLocation(
            id: location.id,
            name: location.name,
            detail: location.detail,
            coordinates: location.coordinates.normalized,
            timeZone: location.timeZone
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = normalizedLocation.timeZone

        var januaryFirstComponents = DateComponents()
        januaryFirstComponents.calendar = calendar
        januaryFirstComponents.timeZone = normalizedLocation.timeZone
        januaryFirstComponents.year = year
        januaryFirstComponents.month = 1
        januaryFirstComponents.day = 1

        guard let januaryFirst = januaryFirstComponents.date,
              let dayRange = calendar.range(of: .day, in: .year, for: januaryFirst)
        else {
            return []
        }

        return stride(from: 0, through: dayRange.count - 1, by: stepDays).compactMap { dayOffset in
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: januaryFirst) else {
                return nil
            }

            let window = daylightWindow(
                for: dayStart,
                calendar: calendar,
                coordinates: normalizedLocation.coordinates,
                timeZone: normalizedLocation.timeZone
            )
            guard window.kind == .normal else {
                return nil
            }
            guard let sunriseDate = window.startDate else {
                return nil
            }
            let duration = daylightDuration(for: window)
            let sampleDate = sunriseDate.addingTimeInterval(Double(boundary) / 12 * duration * 60)

            let julianDay = julianDay(from: sampleDate)
            let solar = solarPosition(julianDay: julianDay, coordinates: normalizedLocation.coordinates)
            return OrlojProjection.projectEquatorial(
                rightAscensionDegrees: solar.rightAscensionDegrees,
                declinationDegrees: solar.declinationDegrees,
                localSiderealTimeDegrees: solar.localSiderealTimeDegrees
            )
        }
    }

    private static func julianDay(from date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    private static func daylightDuration(for window: OrlojSolarWindow) -> Double {
        switch window.kind {
        case .normal:
            if let startDate = window.startDate, let endDate = window.endDate {
                endDate.timeIntervalSince(startDate) / 60
            } else {
                minutesBetween(window.startMinutes, window.endMinutes)
            }
        case .alwaysAbove:
            1440
        case .alwaysBelow:
            0
        }
    }

    private static func minutesBetween(_ start: Double, _ end: Double) -> Double {
        var value = end - start
        if value < 0 {
            value += 1440
        }
        return value
    }

    private static func solarPosition(julianDay: Double, coordinates: OrlojCoordinates) -> SolarPosition {
        let daysSinceJ2000 = julianDay - 2_451_545.0
        let meanLongitude = normalizedDegrees(280.46646 + 0.98564736 * daysSinceJ2000)
        let meanAnomaly = normalizedDegrees(357.52911 + 0.98560028 * daysSinceJ2000)
        let anomalyRadians = degreesToRadians(meanAnomaly)
        let eclipticLongitude = normalizedDegrees(
            meanLongitude
            + 1.914602 * sin(anomalyRadians)
            + 0.019993 * sin(2 * anomalyRadians)
        )
        let obliquity = 23.439291 - 0.00000036 * daysSinceJ2000
        let eccentricity = 0.016708634 - 0.000000042037 * daysSinceJ2000

        let lambdaRadians = degreesToRadians(eclipticLongitude)
        let obliquityRadians = degreesToRadians(obliquity)
        let rightAscension = normalizedDegrees(radiansToDegrees(atan2(cos(obliquityRadians) * sin(lambdaRadians), cos(lambdaRadians))))
        let declination = asin(sin(obliquityRadians) * sin(lambdaRadians))

        let localSiderealTime = normalizedDegrees(280.46061837 + 360.98564736629 * daysSinceJ2000 + coordinates.longitude)
        var hourAngle = normalizedDegrees(localSiderealTime - rightAscension)
        if hourAngle > 180 {
            hourAngle -= 360
        }

        let latitudeRadians = degreesToRadians(coordinates.latitude)
        let hourAngleRadians = degreesToRadians(hourAngle)
        let altitude = asin(
            sin(latitudeRadians) * sin(declination)
            + cos(latitudeRadians) * cos(declination) * cos(hourAngleRadians)
        )
        let azimuth = atan2(
            -sin(hourAngleRadians),
            tan(declination) * cos(latitudeRadians) - sin(latitudeRadians) * cos(hourAngleRadians)
        )
        let meanLongitudeRadians = degreesToRadians(meanLongitude)
        let y = pow(tan(obliquityRadians / 2), 2)
        let equationOfTime = 4 * radiansToDegrees(
            y * sin(2 * meanLongitudeRadians)
            - 2 * eccentricity * sin(anomalyRadians)
            + 4 * eccentricity * y * sin(anomalyRadians) * cos(2 * meanLongitudeRadians)
            - 0.5 * y * y * sin(4 * meanLongitudeRadians)
            - 1.25 * eccentricity * eccentricity * sin(2 * anomalyRadians)
        )

        return SolarPosition(
            altitudeDegrees: radiansToDegrees(altitude),
            azimuthDegrees: normalizedDegrees(radiansToDegrees(azimuth)),
            eclipticLongitudeDegrees: eclipticLongitude,
            declinationDegrees: radiansToDegrees(declination),
            rightAscensionDegrees: rightAscension,
            localSiderealTimeDegrees: localSiderealTime,
            obliquityDegrees: obliquity,
            equationOfTimeMinutes: equationOfTime
        )
    }

    private static func lunarState(
        julianDay: Double,
        solarEclipticLongitude: Double,
        obliquityDegrees: Double
    ) -> LunarState {
        let days = julianDay - 2_451_543.5
        let ascendingNode = normalizedDegrees(125.1228 - 0.0529538083 * days)
        let inclination = 5.1454
        let argumentOfPerigee = normalizedDegrees(318.0634 + 0.1643573223 * days)
        let eccentricity = 0.054900
        let meanAnomaly = normalizedDegrees(115.3654 + 13.0649929509 * days)
        let meanAnomalyRadians = degreesToRadians(meanAnomaly)
        let eccentricAnomaly = meanAnomaly
            + radiansToDegrees(eccentricity * sin(meanAnomalyRadians) * (1 + eccentricity * cos(meanAnomalyRadians)))
        let eccentricAnomalyRadians = degreesToRadians(eccentricAnomaly)
        let xv = cos(eccentricAnomalyRadians) - eccentricity
        let yv = sqrt(1 - eccentricity * eccentricity) * sin(eccentricAnomalyRadians)
        let trueAnomaly = atan2(yv, xv)
        let orbitalRadius = hypot(xv, yv)
        let nodeRadians = degreesToRadians(ascendingNode)
        let inclinationRadians = degreesToRadians(inclination)
        let argumentRadians = degreesToRadians(argumentOfPerigee) + trueAnomaly
        let xh = orbitalRadius * (cos(nodeRadians) * cos(argumentRadians) - sin(nodeRadians) * sin(argumentRadians) * cos(inclinationRadians))
        let yh = orbitalRadius * (sin(nodeRadians) * cos(argumentRadians) + cos(nodeRadians) * sin(argumentRadians) * cos(inclinationRadians))
        let zh = orbitalRadius * sin(argumentRadians) * sin(inclinationRadians)
        let eclipticLongitude = normalizedDegrees(radiansToDegrees(atan2(yh, xh)))
        let eclipticLatitude = radiansToDegrees(atan2(zh, hypot(xh, yh)))
        let equatorial = OrlojProjection.eclipticToEquatorial(
            longitudeDegrees: eclipticLongitude,
            latitudeDegrees: eclipticLatitude,
            obliquityDegrees: obliquityDegrees
        )
        let phaseAngle = normalizedDegrees(eclipticLongitude - solarEclipticLongitude)
        let phaseFraction = phaseAngle / 360
        let age = phaseFraction * synodicMonth
        let illumination = (1 - cos(degreesToRadians(phaseAngle))) / 2

        let phaseName: String
        switch phaseFraction {
        case 0..<0.03, 0.97...1:
            phaseName = "New"
        case 0.03..<0.22:
            phaseName = "Waxing crescent"
        case 0.22..<0.28:
            phaseName = "First quarter"
        case 0.28..<0.47:
            phaseName = "Waxing gibbous"
        case 0.47..<0.53:
            phaseName = "Full"
        case 0.53..<0.72:
            phaseName = "Waning gibbous"
        case 0.72..<0.78:
            phaseName = "Last quarter"
        default:
            phaseName = "Waning crescent"
        }

        return LunarState(
            ageDays: age,
            phaseFraction: phaseFraction,
            revolutionFraction: phaseFraction,
            phaseAngleDegrees: phaseAngle,
            eclipticLongitudeDegrees: eclipticLongitude,
            eclipticLatitudeDegrees: eclipticLatitude,
            declinationDegrees: equatorial.declinationDegrees,
            rightAscensionDegrees: equatorial.rightAscensionDegrees,
            illumination: illumination,
            phaseName: phaseName
        )
    }

    private static func daylightWindow(
        for date: Date,
        calendar: Calendar,
        coordinates: OrlojCoordinates,
        timeZone: TimeZone,
        zenithDegrees: Double = 90
    ) -> OrlojSolarWindow {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let gamma = 2 * .pi / 365 * (Double(dayOfYear) - 1)
        let equationOfTime = 229.18 * (
            0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma)
        )
        let declination = 0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.00148 * sin(3 * gamma)

        let latitudeRadians = degreesToRadians(coordinates.latitude)
        let zenith = degreesToRadians(zenithDegrees)
        let hourAngleCosine = (cos(zenith) / (cos(latitudeRadians) * cos(declination))) - tan(latitudeRadians) * tan(declination)
        if hourAngleCosine < -1 {
            return .alwaysAbove
        }
        if hourAngleCosine > 1 {
            return .alwaysBelow
        }

        let hourAngle = acos(hourAngleCosine)
        let hourAngleDegrees = radiansToDegrees(hourAngle)
        let timezoneOffset = Double(timeZone.secondsFromGMT(for: date)) / 60
        let sunrise = 720 - 4 * (coordinates.longitude + hourAngleDegrees) - equationOfTime + timezoneOffset
        let sunset = 720 - 4 * (coordinates.longitude - hourAngleDegrees) - equationOfTime + timezoneOffset

        // Build the event instant before wrapping its wall-clock minutes. The
        // formula used the offset at `date`; subtract that same offset here so
        // a DST change between now and sunset does not shift the physical event.
        // Retaining unwrapped minutes also preserves events on an adjacent day.
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = .gmt
        let nominalDay = utcCalendar.date(from: calendar.dateComponents([.year, .month, .day], from: date))
        let sunriseDate = nominalDay?.addingTimeInterval((sunrise - timezoneOffset) * 60)
        let sunsetDate = nominalDay?.addingTimeInterval((sunset - timezoneOffset) * 60)
        let sunriseEventOffset = sunriseDate.map { Double(timeZone.secondsFromGMT(for: $0)) / 60 } ?? timezoneOffset
        let sunsetEventOffset = sunsetDate.map { Double(timeZone.secondsFromGMT(for: $0)) / 60 } ?? timezoneOffset
        return .normal(
            startMinutes: (sunrise - timezoneOffset + sunriseEventOffset).wrappedMinutes,
            endMinutes: (sunset - timezoneOffset + sunsetEventOffset).wrappedMinutes,
            startDate: sunriseDate,
            endDate: sunsetDate
        )
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

private extension Double {
    var wrappedMinutes: Double {
        var value = truncatingRemainder(dividingBy: 1440)
        if value < 0 {
            value += 1440
        }
        return value
    }
}

private extension Int {
    func positiveModulo(_ divisor: Int) -> Int {
        let remainder = self % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}
