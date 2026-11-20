//
//  astologia_hologiaTests.swift
//  astologia hologiaTests
//
//  Created by Shubeu on 5/6/26.
//

import CoreLocation
import Foundation
import SwiftUI
import Testing
@testable import astologia_hologia

struct astologia_hologiaTests {
    @Test func springSunFallsInAries() {
        let state = OrlojCalculator.state(for: utcDate(year: 2026, month: 3, day: 22, hour: 12))

        #expect(state.location.id == OrlojClockLocation.prague.id)
        #expect(state.location.timeZone.identifier == "Europe/Prague")
        #expect(state.zodiacSign.name == "Aries")
        #expect((0...1).contains(state.dayProgress))
        #expect((0...1).contains(state.lunar.phaseFraction))
    }

    @Test func seoulSummerNoonSunIsHigherThanWinterNoonSun() {
        let summerNoon = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 6, day: 21, hour: 3),
            location: .seoul
        )
        let winterNoon = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 12, day: 21, hour: 3),
            location: .seoul
        )

        #expect(summerNoon.solar.altitudeDegrees > winterNoon.solar.altitudeDegrees)
        #expect(summerNoon.sunriseMinutes < summerNoon.sunsetMinutes)
        #expect(winterNoon.sunriseMinutes < winterNoon.sunsetMinutes)
    }

    @Test func oldCzechHourStartsAtSunset() {
        #expect(OrlojCalculator.oldCzechHour(localMinutes: 18 * 60, sunsetMinutes: 18 * 60) == 24)
        #expect(OrlojCalculator.oldCzechHour(localMinutes: 18 * 60 + 30, sunsetMinutes: 18 * 60) == 1)
        #expect(OrlojCalculator.oldCzechHour(localMinutes: 23 * 60, sunsetMinutes: 18 * 60) == 5)
        #expect(OrlojCalculator.oldCzechHour(localMinutes: 1 * 60, sunsetMinutes: 18 * 60) == 7)
    }

    @Test func coordinatesChangeDaylightGeometry() {
        let date = utcDate(year: 2026, month: 6, day: 21, hour: 10)
        let seoul = OrlojCalculator.state(for: date, location: .seoul)
        let westernReference = OrlojCalculator.state(
            for: date,
            coordinates: OrlojCoordinates(latitude: 50.087, longitude: -3)
        )

        #expect(abs(seoul.sunriseMinutes - westernReference.sunriseMinutes) > 30)
        #expect(seoul.solar.altitudeDegrees != westernReference.solar.altitudeDegrees)
    }

    @Test func praguePresetKeepsOriginalMoodOption() {
        let date = utcDate(year: 2026, month: 5, day: 6, hour: 12)
        let state = OrlojCalculator.state(for: date, location: .prague)

        #expect(state.location.id == OrlojClockLocation.prague.id)
        #expect(state.location.timeZone.identifier == "Europe/Prague")
        #expect(state.location.coordinates.latitude == OrlojCoordinates.prague.latitude)
        #expect(state.location.coordinates.longitude == OrlojCoordinates.prague.longitude)
    }

    @Test func pragueDialUsesCETInWinterAndSummerWhileLocalTimeKeepsDST() {
        let winter = OrlojCalculator.state(for: utcDate(year: 2026, month: 12, day: 21, hour: 11))
        let summer = OrlojCalculator.state(for: utcDate(year: 2026, month: 6, day: 21, hour: 11))

        #expect(winter.dialTimeString == "12:00")
        #expect(summer.dialTimeString == "12:00")
        #expect(winter.localDecimalHour == 12)
        #expect(summer.localDecimalHour == 13)
        #expect(summer.dialTimeZoneLabel == "CET")
        #expect(abs(summer.dialSunsetMinutes - (summer.sunsetMinutes - 60)) < 0.000001)
        #expect(abs(winter.dialSunsetMinutes - winter.sunsetMinutes) < 0.000001)
        #expect(summer.oldCzechHour == OrlojCalculator.oldCzechHour(
            localMinutes: summer.dialDecimalHour * 60,
            sunsetMinutes: summer.dialSunsetMinutes
        ))

        let before = OrlojCalculator.state(for: utcDate(year: 2026, month: 3, day: 29, hour: 0).addingTimeInterval(59 * 60))
        let after = OrlojCalculator.state(for: utcDate(year: 2026, month: 3, day: 29, hour: 1))
        #expect(before.dialTimeString == "01:59")
        #expect(after.dialTimeString == "02:00")
        #expect(after.localDecimalHour == 3)
        #expect(abs(after.civilAngleDegrees - before.civilAngleDegrees - 0.25) < 0.000001)

        let readout = OrlojAstronomyReadout(state: summer)
        #expect(readout.localTime == summer.localTimeString)
        #expect(readout.primaryMetrics.first { $0.title == "Dial time" }?.guideTopic == .romanTime)
        #expect(readout.primaryMetrics.first { $0.title == "Local time" }?.guideTopic == nil)
    }

    @Test func pragueDialSunIntersectsBothCETRayAndEcliptic() {
        for month in [3, 6, 9, 12] {
            for hour in [0, 6, 11, 18, 23] {
                let state = OrlojCalculator.state(for: utcDate(year: 2026, month: month, day: 21, hour: hour))
                let point = state.dialSunProjection
                let handAngle = state.civilAngleDegrees * .pi / 180
                // The point must lie on the positive hand ray, not its opposite.
                #expect(abs(point.x * cos(handAngle) - point.y * sin(handAngle)) < 0.000001)
                #expect(point.x * sin(handAngle) + point.y * cos(handAngle) > 0)
                #expect(abs(eclipticLatitudeSine(of: point, state: state)) < 0.000001)
            }
        }

        let noon = OrlojCalculator.state(for: utcDate(year: 2026, month: 6, day: 21, hour: 11))
        let sunsetDate = utcDate(year: 2026, month: 6, day: 21, hour: 0)
            .addingTimeInterval((noon.dialSunsetMinutes - 60) * 60)
        let sunset = OrlojCalculator.state(for: sunsetDate)
        let sunAngle = atan2(sunset.dialSunProjection.x, sunset.dialSunProjection.y) * 180 / .pi
        #expect(abs(sunAngle - sunset.sunsetAngleDegrees) < 0.005)
        #expect(OrlojCalculator.state(for: sunsetDate.addingTimeInterval(60)).oldCzechHour == 1)
    }

    @Test func pragueDialConstrainsMoonToEclipticWithoutChangingItsRealCoordinates() {
        let state = OrlojCalculator.state(for: utcDate(year: 2026, month: 5, day: 6, hour: 12))
        #expect(abs(eclipticLatitudeSine(of: state.dialMoonProjection, state: state)) < 0.000001)
        #expect(abs(eclipticLatitudeSine(of: state.moonProjection, state: state)
            - sin(state.lunar.eclipticLatitudeDegrees * .pi / 180)) < 0.000001)
        #expect(abs(state.lunar.eclipticLatitudeDegrees) > 0.1)
        #expect(state.dialMoonProjection != state.moonProjection)
        #expect(OrlojAstronomyReadout(state: state).moonPhase == state.lunar.phaseName)
    }

    @Test func manualPragueKeepsPersonalSkyProjectionsAndReadsApparentSolarTime() {
        var location = OrlojLocationState.prague
        location.markManual()
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 6, day: 21, hour: 11),
            location: location.resolvedLocation
        )
        #expect(!state.isPragueMechanism)
        #expect(state.dialSunProjection == state.sunProjection)
        #expect(state.dialMoonProjection == state.moonProjection)
        #expect(state.localDecimalHour == 13)
        #expect(abs(state.dialDecimalHour - state.localDecimalHour) > 1)
        #expect(state.dialSolarLongitudeDegrees == state.solar.eclipticLongitudeDegrees)
        #expect(state.dialTimeZoneLabel == "solar")
        let readout = OrlojAstronomyReadout(state: state)
        #expect(readout.localTime == state.localTimeString)
        #expect(readout.primaryMetrics.first { $0.title == "Local time" }?.guideTopic == nil)
        #expect(readout.primaryMetrics.first { $0.title == "Apparent solar time" }?.guideTopic == .romanTime)
    }

    @Test func mySkyRomanHandAndOldCzechRingFollowTheTrueSun() throws {
        let locations: [OrlojClockLocation] = [
            .seoul,
            .custom(name: "Manual Prague", coordinates: .prague, timeZone: OrlojClockLocation.prague.timeZone),
            .custom(
                name: "Cape Town",
                coordinates: OrlojCoordinates(latitude: -33.925, longitude: 18.424),
                timeZone: try #require(TimeZone(identifier: "Africa/Johannesburg"))
            )
        ]
        for location in locations {
            for month in [6, 12] {
                let state = OrlojCalculator.state(
                    for: utcDate(year: 2026, month: month, day: 21, hour: 12),
                    location: location
                )
                #expect(state.dialSunProjection == state.sunProjection)
                let handAngle = state.civilAngleDegrees * .pi / 180
                let point = state.sunProjection
                #expect(abs(point.x * cos(handAngle) - point.y * sin(handAngle)) < 0.000001)
                #expect(point.x * sin(handAngle) + point.y * cos(handAngle) > 0)

                let sunsetDate = try #require(state.daylightWindow.endDate)
                let sunset = OrlojCalculator.state(for: sunsetDate, location: location)
                let sunsetRay = atan2(sunset.sunProjection.x, sunset.sunProjection.y)
                #expect(abs(sin(sunsetRay - state.sunsetAngleDegrees * .pi / 180)) < 0.000001)
                #expect(cos(sunsetRay - state.sunsetAngleDegrees * .pi / 180) > 0)
                #expect(OrlojCalculator.state(for: sunsetDate.addingTimeInterval(-60), location: location).oldCzechHour == 24)
                #expect(OrlojCalculator.state(for: sunsetDate.addingTimeInterval(60), location: location).oldCzechHour == 1)

                // Read the outer ring directly from the two projected rays.
                let currentRay = atan2(point.x, point.y)
                let elapsedDegrees = OrlojCalculator.normalizedDegrees((currentRay - sunsetRay) * 180 / .pi)
                let ringHour = max(1, min(24, Int(ceil(elapsedDegrees / 15))))
                #expect(state.oldCzechHour == ringHour)
            }
        }
    }

    @Test func sunsetEventAndSolarHandStayContinuousAcrossPragueDSTChange() throws {
        let location = OrlojClockLocation.custom(name: "Manual Prague", coordinates: .prague, timeZone: OrlojClockLocation.prague.timeZone)
        let beforeDate = utcDate(year: 2026, month: 3, day: 29, hour: 0).addingTimeInterval(59 * 60)
        let afterDate = beforeDate.addingTimeInterval(60)
        let before = OrlojCalculator.state(for: beforeDate, location: location)
        let after = OrlojCalculator.state(for: afterDate, location: location)
        #expect(abs(after.localDecimalHour - before.localDecimalHour - 61.0 / 60) < 0.000001)
        #expect(abs(after.dialDecimalHour - before.dialDecimalHour - 1.0 / 60) < 0.00001)
        let beforeSunset = try #require(before.daylightWindow.endDate)
        let afterSunset = try #require(after.daylightWindow.endDate)
        #expect(abs(afterSunset.timeIntervalSince(beforeSunset)) < 0.000001)
        #expect(abs(after.sunsetAngleDegrees - before.sunsetAngleDegrees) < 0.000001)
        #expect(abs(after.sunsetMinutes - before.sunsetMinutes) < 0.000001)
        // The local sunset label uses CEST even before the overnight switch.
        let sunsetUTCMinutes = (beforeSunset.timeIntervalSince1970 / 60).truncatingRemainder(dividingBy: 1440)
        #expect(abs(before.sunsetMinutes - sunsetUTCMinutes - 120) < 0.000001)

        let mechanicalBefore = OrlojCalculator.state(for: beforeDate)
        let mechanicalAfter = OrlojCalculator.state(for: afterDate)
        #expect(abs(mechanicalAfter.sunsetAngleDegrees - mechanicalBefore.sunsetAngleDegrees) < 0.000001)
        #expect(abs(mechanicalBefore.dialSunsetMinutes - sunsetUTCMinutes - 60) < 0.000001)
    }

    @Test func solarEventProjectionPreservesAdjacentDateWhenLongitudeAndZoneDiffer() throws {
        let location = OrlojClockLocation.custom(
            name: "Dateline in UTC",
            coordinates: OrlojCoordinates(latitude: 20, longitude: 180),
            timeZone: .gmt
        )
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 6, day: 21, hour: 0),
            location: location
        )
        let sunriseDate = try #require(state.daylightWindow.startDate)
        let sunsetDate = try #require(state.daylightWindow.endDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        #expect(calendar.component(.day, from: sunriseDate) == 20)
        #expect(calendar.component(.day, from: sunsetDate) == 21)
        #expect(sunsetDate.timeIntervalSince(sunriseDate) > 12 * 3600)
        #expect(sunsetDate.timeIntervalSince(sunriseDate) < 24 * 3600)
        for (eventDate, dialAngle) in [(sunriseDate, state.sunriseAngleDegrees), (sunsetDate, state.sunsetAngleDegrees)] {
            let event = OrlojCalculator.state(for: eventDate, location: location)
            let eventRay = atan2(event.sunProjection.x, event.sunProjection.y)
            #expect(abs(sin(eventRay - dialAngle * .pi / 180)) < 0.000001)
            #expect(cos(eventRay - dialAngle * .pi / 180) > 0)
        }
    }

    @Test func twilightBoundsSurroundSunriseAndSunset() {
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .seoul
        )

        #expect(state.dawnMinutes < state.sunriseMinutes)
        #expect(state.sunsetMinutes < state.duskMinutes)
        #expect(state.nightIntervalLabel == "\(state.duskTimeString)-\(state.dawnTimeString)")
    }

    @Test func seoulAndPraguePresetsProduceDifferentSolarWindows() {
        let date = utcDate(year: 2026, month: 5, day: 6, hour: 12)
        let seoul = OrlojCalculator.state(for: date, location: .seoul)
        let prague = OrlojCalculator.state(for: date, location: .prague)
        let seoulDaylight = seoul.sunsetMinutes - seoul.sunriseMinutes
        let pragueDaylight = prague.sunsetMinutes - prague.sunriseMinutes

        #expect(abs(seoul.sunsetMinutes - prague.sunsetMinutes) > 10)
        #expect(abs(seoulDaylight - pragueDaylight) > 30)
    }

    @Test func customCoordinatesPreserveHighLatitudesAndClampInvalidLongitude() {
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 5, day: 6, hour: 12),
            coordinates: OrlojCoordinates(latitude: 89, longitude: 210)
        )

        #expect(state.location.coordinates.latitude == 89)
        #expect(state.location.coordinates.longitude == 180)
    }

    @Test func equatorialHorizonProjectionUsesFiniteLineBoundary() {
        let boundary = OrlojProjection.constantAltitudeBoundary(
            latitudeDegrees: 0,
            altitudeDegrees: 0
        )

        if case .lineY(let y) = boundary {
            #expect(y.isFinite)
            #expect(abs(y) < 0.000001)
        } else {
            Issue.record("Expected equatorial horizon to use a finite line boundary")
        }
    }

    @Test func southernTwilightSingularityUsesOffsetLineBoundary() {
        let boundary = OrlojProjection.constantAltitudeBoundary(
            latitudeDegrees: -18,
            altitudeDegrees: -18
        )

        if case .lineY(let y) = boundary {
            let expected = tan(OrlojCalculator.degreesToRadians(-18))
            #expect(y.isFinite)
            #expect(abs(y - expected) < 0.000001)
        } else {
            Issue.record("Expected the southern twilight singularity to use a line boundary")
        }
    }

    @Test func southernNoonAndMidnightUseTheCorrectPaintedSkyRegions() {
        let coordinates = OrlojCoordinates(latitude: -33, longitude: 0)
        let noon = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 3, day: 20, hour: 12),
            coordinates: coordinates,
            timeZone: .gmt
        )
        let midnight = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 3, day: 20, hour: 0),
            coordinates: coordinates,
            timeZone: .gmt
        )

        #expect(noon.solar.altitudeDegrees > 50)
        #expect(midnight.solar.altitudeDegrees < -50)
        for (state, expectedBelow) in [(noon, false), (midnight, true)] {
            for altitude in [0.0, -18.0] {
                let boundary = OrlojProjection.constantAltitudeBoundary(
                    latitudeDegrees: coordinates.latitude,
                    altitudeDegrees: altitude
                )
                #expect(paintedRegionContains(state.sunProjection, boundary: boundary, belowBoundary: true) == expectedBelow)
                #expect(paintedRegionContains(state.sunProjection, boundary: boundary, belowBoundary: false) != expectedBelow)
            }
        }
    }

    @Test func paintedAltitudeRegionsMatchSphericalAltitudeAcrossBothSingularities() {
        // Test both sides of the horizon (0°) and twilight (-18°) line limits,
        // as well as the original Prague geometry and a southern sky.
        for latitude in [-50.087, -33, -18.1, -18, -17.9, -0.1, 0, 0.1, 50.087] {
            for boundaryAltitude in [0.0, -18.0] {
                let boundary = OrlojProjection.constantAltitudeBoundary(
                    latitudeDegrees: latitude,
                    altitudeDegrees: boundaryAltitude
                )
                for declination in [-23.4, 0, 23.4] {
                    for hourAngle in [-180.0, -120, -96, -90, -60, 0, 60, 90, 96, 120, 180] {
                        let radians = Double.pi / 180
                        let altitude = asin(
                            sin(latitude * radians) * sin(declination * radians)
                            + cos(latitude * radians) * cos(declination * radians) * cos(hourAngle * radians)
                        ) / radians
                        // The boundary itself belongs to both fills; compare points
                        // clearly on either side, using spherical altitude as oracle.
                        guard abs(altitude - boundaryAltitude) > 0.5 else { continue }
                        let point = OrlojProjection.projectEquatorial(
                            rightAscensionDegrees: 0,
                            declinationDegrees: declination,
                            localSiderealTimeDegrees: hourAngle
                        )
                        let expectedBelow = altitude < boundaryAltitude
                        #expect(paintedRegionContains(point, boundary: boundary, belowBoundary: true) == expectedBelow)
                        #expect(paintedRegionContains(point, boundary: boundary, belowBoundary: false) != expectedBelow)
                    }
                }
            }
        }
    }

    @Test func equatorialCustomStateKeepsProjectionValuesFinite() {
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 3, day: 20, hour: 12),
            coordinates: OrlojCoordinates(latitude: 0, longitude: 0),
            timeZone: TimeZone(secondsFromGMT: 0) ?? .gmt
        )

        #expect(state.sunProjection.x.isFinite)
        #expect(state.sunProjection.y.isFinite)
        #expect(state.moonProjection.x.isFinite)
        #expect(state.moonProjection.y.isFinite)
        #expect(OrlojAstronomyReadout(state: state).coordinates == "0.000, 0.000")
    }

    @Test func pragueMidsummerReportsNoAstronomicalNight() {
        let state = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 6, day: 21, hour: 12),
            location: .prague
        )

        #expect(state.twilightWindow.kind == .alwaysAbove)
        #expect(state.twilightIntervalLabel == "No astronomical night")
        #expect(OrlojAstronomyReadout(state: state).dawnDusk == "No astronomical night")
    }

    @Test func timeStateSeparatesLiveAndManualMoments() {
        let liveDate = utcDate(year: 2026, month: 5, day: 6, hour: 12)
        let manualDate = utcDate(year: 2027, month: 1, day: 2, hour: 3)
        var timeState = OrlojTimeState.live

        #expect(timeState.mode == .live)
        #expect(timeState.manualDateTime == nil)
        #expect(timeState.resolvedDate(liveDate: liveDate) == liveDate)

        timeState.useManual(manualDate)
        #expect(timeState.mode == .manual)
        #expect(timeState.manualDateTime == manualDate)
        #expect(timeState.resolvedDate(liveDate: liveDate) == manualDate)

        timeState.useLiveNow()
        #expect(timeState.mode == .live)
        #expect(timeState.manualDateTime == nil)
    }

    @Test func locationStateAppliesDeviceFixWithMeasuredAccuracy() {
        var locationState = OrlojLocationState.prague
        locationState.applyDeviceGPS(
            OrlojLocationFix(
                location: .detected(
                    name: "Detected Place",
                    coordinates: OrlojCoordinates(latitude: 10, longitude: 20),
                    timeZone: TimeZone(identifier: "Asia/Tokyo") ?? .current
                ),
                precision: .precise,
                horizontalAccuracyMeters: 850
            )
        )

        #expect(locationState.mode == .device)
        #expect(locationState.basis == .gps)
        #expect(locationState.label == "Detected Place")
        #expect(locationState.coordinates == OrlojCoordinates(latitude: 10, longitude: 20))
        #expect(locationState.timezone == "Asia/Tokyo")
        #expect(locationState.precision == .precise)
        #expect(locationState.horizontalAccuracyMeters == 850)
        #expect(locationState.precisionLabel.contains("850 m"))
    }

    @Test func switchingPragueToManualRetainsTheDialCoordinates() {
        var location = OrlojLocationState.prague
        #expect(location.coordinates == .prague)
        location.markManual()
        #expect(location.resolvedLocation.coordinates == .prague)
    }

    @Test func failedDeviceRequestKeepsCommittedLocation() {
        var locationState = OrlojLocationState.prague
        let coordinates = locationState.coordinates
        let timezone = locationState.timezone

        locationState.recordLocationRequestFailure("Device location unavailable. Keeping the current location.")

        #expect(locationState.mode == .prague)
        #expect(locationState.basis == .praguePreset)
        #expect(locationState.label == "Prague Orloj")
        #expect(locationState.coordinates == coordinates)
        #expect(locationState.timezone == timezone)
        #expect(locationState.precision == .exact)
        #expect(locationState.statusMessage?.contains("Keeping the current location") == true)
    }

    @Test func locationRequestGateRejectsCanceledResults() {
        var gate = OrlojLocationRequestGate()
        let firstRequest = gate.begin()
        #expect(gate.accepts(firstRequest))

        gate.cancel()
        #expect(!gate.accepts(firstRequest))

        let secondRequest = gate.begin()
        #expect(!gate.accepts(firstRequest))
        #expect(gate.accepts(secondRequest))
    }

    @Test func deviceAccuracyAuthorizationMapsToDisplayPrecision() {
        #expect(OrlojLocationProvider.precision(for: .fullAccuracy) == .precise)
        #expect(OrlojLocationProvider.precision(for: .reducedAccuracy) == .approximate)
    }

    @Test func locationStateSeparatesPragueOrlojAndMySkyConcepts() {
        var locationState = OrlojLocationState.prague

        #expect(locationState.conceptualModeTitle == "Prague Orloj")
        #expect(locationState.conceptualModeDetail.contains("Historical Prague"))
        #expect(locationState.basis.rawValue == "prague-preset")

        locationState.applyDeviceGPS(
            OrlojLocationFix(
                location: .seoul,
                precision: .precise,
                horizontalAccuracyMeters: 1_200
            )
        )
        #expect(locationState.conceptualModeTitle == "My Sky")
        #expect(locationState.conceptualModeDetail.contains("device"))
        #expect(locationState.basis == .gps)

        locationState.markManual()
        #expect(locationState.conceptualModeTitle == "My Sky")
        #expect(locationState.conceptualModeDetail.contains("manual"))
        #expect(locationState.basis == .manual)
    }

    @Test func guideTopicsDeclareTargetDialLayers() {
        #expect(OrlojGuideCatalog.items.count == OrlojGuideTopicID.allCases.count)
        #expect(OrlojGuideCatalog.item(for: .romanTime)?.targetLayers.contains(.romanTimeRing) == true)
        #expect(OrlojGuideCatalog.item(for: .oldCzechTime)?.targetLayers.contains(.sunsetAlignmentMarker) == true)
        #expect(OrlojGuideCatalog.item(for: .sun)?.targetLayers.contains(.sunMarker) == true)
        #expect(OrlojGuideCatalog.item(for: .moon)?.targetLayers.contains(.moonPhase) == true)
        #expect(OrlojGuideCatalog.item(for: .zodiacRing)?.targetLayers.contains(.eclipticPath) == true)
        #expect(OrlojGuideCatalog.item(for: .horizon)?.targetLayers.contains(.horizonCurve) == true)
        #expect(OrlojGuideCatalog.item(for: .twilight)?.targetLayers.contains(.nightBoundary) == true)
        #expect(OrlojGuideCatalog.item(for: .unequalHours)?.targetLayers.contains(.unequalHourLines) == true)
        #expect(OrlojGuideCatalog.item(for: .siderealAries)?.targetLayers.contains(.ariesStar) == true)
        #expect(OrlojGuideCatalog.item(for: .tropics)?.targetLayers.contains(.tropicCancer) == true)
        #expect(OrlojGuideCatalog.items.allSatisfy { !$0.targetLayers.isEmpty })
    }

    @Test func guideCatalogResolvesCurrentValuesFromReadout() {
        let state = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .prague
        )
        let readout = OrlojAstronomyReadout(state: state)
        let resolvedItems = OrlojGuideCatalog.resolvedItems(readout: readout)

        #expect(resolvedItems.count == OrlojGuideCatalog.items.count)
        #expect(resolvedItems.allSatisfy { $0.currentValue?.isEmpty == false })
        #expect(resolvedItems.first { $0.id == .sun }?.targetLayerSet.contains(.sunHand) == true)
    }

    @Test func dialModesSeparateFinishedGuideAndDebugViews() {
        #expect(OrlojDialMode.allCases == [.display, .guide, .debug])
        #expect(OrlojDialMode.display.detail.contains("Finished"))
        #expect(OrlojDialMode.guide.detail.contains("Teaching"))
        #expect(OrlojDialMode.debug.detail.contains("technical"))
    }

    @Test func dialFocusStateIsSharedAcrossManualGuideAndReadoutFocus() throws {
        let state = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .prague
        )
        let readout = OrlojAstronomyReadout(state: state)
        let sunGuideItem = try #require(OrlojGuideCatalog.resolvedItem(for: .sun, readout: readout))

        let manualSun = OrlojDialFocusState.manualFocus(.sun)
        #expect(manualSun.mode == .guide)
        #expect(manualSun.focus == .sun)
        #expect(manualSun.activeGuideItemId == nil)
        #expect(manualSun.targetLayers.contains(.sunMarker))
        #expect(manualSun.showAnnotations == false)

        let guideSun = OrlojDialFocusState.guide(item: sunGuideItem)
        #expect(guideSun.mode == .guide)
        #expect(guideSun.focus == .sun)
        #expect(guideSun.activeGuideItemId == .sun)
        #expect(guideSun.targetLayers == sunGuideItem.targetLayerSet)
        #expect(guideSun.showAnnotations == true)

        let readoutSun = OrlojDialFocusState.readout(item: sunGuideItem)
        #expect(readoutSun.mode == .guide)
        #expect(readoutSun.focus == .sun)
        #expect(readoutSun.activeGuideItemId == nil)
        #expect(readoutSun.targetLayers == sunGuideItem.targetLayerSet)
        #expect(readoutSun.showAnnotations == false)
    }

    @Test func unequalHourNumeralsOccupyTheirDaylightSectorsInsideTheRomanScale() {
        for latitude in [50.087, 0, -33, -66, 66] {
            let positions = OrlojCalculator.unequalHourLabelPositions(latitudeDegrees: latitude)
            #expect(positions.count == 12)
            #expect(positions.first!.x < 0)
            #expect(positions.last!.x > 0)

            for (index, point) in positions.enumerated() {
                // Recover the celestial coordinate from the projected point,
                // then independently locate it within the visible diurnal arc.
                let declination = 2 * atan(point.radius) - .pi / 2
                let latitudeRadians = latitude * .pi / 180
                let hourAngle = atan2(point.x, point.y)
                let altitude = asin(
                    sin(latitudeRadians) * sin(declination)
                    + cos(latitudeRadians) * cos(declination) * cos(hourAngle)
                )
                let halfDay = acos(-tan(latitudeRadians) * tan(declination))
                let temporalHour = (hourAngle + halfDay) / (2 * halfDay) * 12
                #expect(altitude > 0)
                #expect(temporalHour > Double(index))
                #expect(temporalHour < Double(index + 1))
                // Production projection scale is 0.43 of the dial radius;
                // the Roman inscriptions sit at 0.765 of that radius.
                #expect(point.radius * 0.43 + 0.052 / 2 < 0.765 - 0.06)
            }
        }
    }

    @Test func unequalHourBoundariesAreStableForSameCacheKey() {
        let first = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .prague
        )
        let second = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 13),
            location: .prague
        )

        #expect(first.unequalHourBoundaries == second.unequalHourBoundaries)
    }

    @Test func astronomyReadoutMirrorsClockStateFormatting() {
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .seoul
        )
        let readout = OrlojAstronomyReadout(state: state)

        #expect(readout.nightInterval == state.nightIntervalLabel)
        #expect(readout.dawnDusk == state.twilightIntervalLabel)
        #expect(readout.zodiacName == state.zodiacSign.name)
        #expect(readout.moonIllumination == state.moonIlluminationLabel)
        #expect(readout.primaryMetrics.contains { $0.value == state.localTimeString })
        #expect(readout.astronomyMetrics.contains { $0.value == state.babylonianHourLabel })
        #expect(readout.primaryMetrics.contains { $0.title == "Twilight" && $0.value == state.twilightIntervalLabel })
        #expect(readout.astronomyMetrics.contains { $0.title == "Sun" && $0.prominence == .primary && $0.guideTopic == .sun })
        #expect(readout.astronomyMetrics.contains { $0.title == "Moon" && $0.prominence == .primary && $0.guideTopic == .moon })
        #expect(readout.astronomyMetrics.contains { $0.title == "Old Czech time" && $0.prominence == .primary && $0.guideTopic == .oldCzechTime })
        #expect(readout.astronomyMetrics.contains { $0.title == "Sidereal" && $0.value == state.siderealTimeString })
        #expect(readout.astronomyMetrics.contains { $0.title == "Ecliptic" && $0.value == state.solarEclipticLongitudeLabel })
        #expect(readout.astronomyMetrics.contains { $0.title == "Coordinates" && $0.guideTopic == nil })
    }

    @Test func astronomyReadoutKeepsCurrentValuesSeparateFromGuideStructure() {
        let readout = OrlojAstronomyReadout(
            state: OrlojCalculator.state(
                for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 12),
                location: .prague
            )
        )

        #expect(readout.primaryMetrics.map(\.title) == ["Dial time", "Local time", "Sunrise / Sunset", "Twilight"])
        #expect(readout.astronomyMetrics.map(\.title) == [
            "Sun",
            "Ecliptic",
            "Sidereal",
            "Moon",
            "Old Czech time",
            "Unequal / Babylonian",
            "Mean solar",
            "Coordinates"
        ])
        #expect(readout.astronomyMetrics.filter { $0.prominence == .primary }.map(\.title) == ["Sun", "Moon", "Old Czech time"])
        #expect(readout.astronomyMetrics.first { $0.title == "Coordinates" }?.guideTopic == nil)
    }

    @Test func projectedSunMovesOutwardInPragueSummerAndInwardInWinter() {
        let summerNoon = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 6, day: 21, hour: 12),
            location: .prague
        )
        let winterNoon = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 12, day: 21, hour: 12),
            location: .prague
        )

        #expect(summerNoon.sunProjection.y > 0)
        #expect(winterNoon.sunProjection.y > 0)
        #expect(summerNoon.sunProjection.radius > winterNoon.sunProjection.radius * 1.8)
        #expect(summerNoon.solarDeclinationRatio > 0.85)
        #expect(winterNoon.solarDeclinationRatio < -0.85)
    }

    @Test func sunriseAndSunsetTouchProjectedHorizon() throws {
        let noon = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 3, day: 20, hour: 12),
            location: .prague
        )
        let sunrise = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 3, day: 20, minutes: Int(noon.sunriseMinutes.rounded())),
            location: .prague
        )
        let sunset = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 3, day: 20, minutes: Int(noon.sunsetMinutes.rounded())),
            location: .prague
        )
        let horizon = try #require(OrlojProjection.constantAltitudeCircle(
            latitudeDegrees: OrlojCoordinates.prague.latitude,
            altitudeDegrees: 0
        ))

        #expect(abs(OrlojProjection.circleEquationValue(point: sunrise.sunProjection, circle: horizon)) < 0.04)
        #expect(abs(OrlojProjection.circleEquationValue(point: sunset.sunProjection, circle: horizon)) < 0.04)
        #expect(sunrise.sunProjection.x < 0)
        #expect(sunset.sunProjection.x > 0)
    }

    @Test func midnightSunIsBelowPragueHorizonCircle() throws {
        let midnight = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 0),
            location: .prague
        )
        let horizon = try #require(OrlojProjection.constantAltitudeCircle(
            latitudeDegrees: OrlojCoordinates.prague.latitude,
            altitudeDegrees: 0
        ))

        #expect(OrlojProjection.circleEquationValue(point: midnight.sunProjection, circle: horizon) < 0)
        #expect(midnight.skyPhaseLabel != "Day")
    }

    @Test func eclipticProjectionIsEccentricNotCenteredZodiacCircle() {
        let state = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .prague
        )
        let cancer = OrlojProjection.projectEcliptic(
            longitudeDegrees: 90,
            obliquityDegrees: state.solar.obliquityDegrees,
            localSiderealTimeDegrees: state.solar.localSiderealTimeDegrees
        )
        let capricorn = OrlojProjection.projectEcliptic(
            longitudeDegrees: 270,
            obliquityDegrees: state.solar.obliquityDegrees,
            localSiderealTimeDegrees: state.solar.localSiderealTimeDegrees
        )

        #expect(cancer.radius > capricorn.radius * 1.8)
        #expect(abs(state.sunProjection.radius - OrlojProjection.projectEcliptic(
            longitudeDegrees: state.solar.eclipticLongitudeDegrees,
            obliquityDegrees: state.solar.obliquityDegrees,
            localSiderealTimeDegrees: state.solar.localSiderealTimeDegrees
        ).radius) < 0.001)
    }

    @Test func oldCzechRingAlignsTwentyFourWithSunsetAngle() {
        let state = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 12, day: 21, hour: 12),
            location: .prague
        )
        let visualTwentyFourAngle = OrlojCalculator.normalizedDegrees(state.sunsetAngleDegrees + Double(24 - 24) * 15)

        #expect(abs(visualTwentyFourAngle - state.sunsetAngleDegrees) < 0.001)
        #expect(state.sunsetMinutes < 17 * 60)
    }

    @Test func moonProjectionAndPhaseUseLunarCoordinates() {
        let state = OrlojCalculator.state(
            for: pragueLocalDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .prague
        )

        #expect(abs(state.moonProjection.x - state.sunProjection.x) > 0.01 || abs(state.moonProjection.y - state.sunProjection.y) > 0.01)
        #expect((0..<360).contains(state.lunar.eclipticLongitudeDegrees))
        #expect((-6...6).contains(state.lunar.eclipticLatitudeDegrees))
        #expect((0..<360).contains(state.lunar.phaseAngleDegrees))
    }

    @Test func siderealAndEclipticIndicatorsAreBounded() {
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .prague
        )

        #expect((0..<360).contains(state.solar.localSiderealTimeDegrees))
        #expect((0..<24).contains(state.siderealDecimalHour))
        #expect((0..<360).contains(state.siderealAngleDegrees))
        #expect((0..<30).contains(state.zodiacDegreeInSign))
        #expect(state.siderealTimeString.count == 5)
        #expect(state.zodiacDegreeLabel.contains(state.zodiacSign.name))
    }

    @Test func moonRevolutionReadoutStaysWithinSynodicCycle() {
        let state = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 5, day: 6, hour: 12),
            location: .seoul
        )

        #expect((0..<29.530588853).contains(state.lunar.ageDays))
        #expect((0...1).contains(state.lunar.revolutionFraction))
        #expect(state.moonRevolutionLabel.contains("rev"))
        #expect(state.moonAgeLabel.hasSuffix("d"))
    }

    @Test func solarDeclinationTracksEquatorAndTropics() {
        let equinox = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 3, day: 20, hour: 12),
            location: .prague
        )
        let summerSolstice = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 6, day: 21, hour: 12),
            location: .prague
        )
        let winterSolstice = OrlojCalculator.state(
            for: utcDate(year: 2026, month: 12, day: 21, hour: 12),
            location: .prague
        )

        #expect(abs(equinox.solar.declinationDegrees) < 2)
        #expect(summerSolstice.solar.declinationDegrees > 20)
        #expect(winterSolstice.solar.declinationDegrees < -20)
        #expect(summerSolstice.solarTropicPositionLabel.contains("Cancer"))
        #expect(winterSolstice.solarTropicPositionLabel.contains("Capricorn"))
    }

    private func eclipticLatitudeSine(of point: OrlojProjectionPoint, state: OrlojClockState) -> Double {
        let declination = 2 * atan(point.radius) - .pi / 2
        let rightAscension = state.solar.localSiderealTimeDegrees * .pi / 180 - atan2(point.x, point.y)
        let obliquity = state.solar.obliquityDegrees * .pi / 180
        return sin(declination) * cos(obliquity)
            - cos(declination) * sin(obliquity) * sin(rightAscension)
    }

    private func paintedRegionContains(
        _ point: OrlojProjectionPoint,
        boundary: OrlojProjectionBoundary,
        belowBoundary: Bool
    ) -> Bool {
        let plateRect = CGRect(x: 0, y: 0, width: 400, height: 400)
        let scale: CGFloat = 100
        let path = OrlojAltitudeRegionPath.make(
            boundary: boundary,
            belowBoundary: belowBoundary,
            plateRect: plateRect,
            projectionScale: scale
        )
        return path.contains(CGPoint(
            x: plateRect.midX + CGFloat(point.x) * scale,
            y: plateRect.midY - CGFloat(point.y) * scale
        ), eoFill: true)
    }

    private func utcDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour

        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    private func pragueLocalDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        pragueLocalDate(year: year, month: month, day: day, minutes: hour * 60)
    }

    private func pragueLocalDate(year: Int, month: Int, day: Int, minutes: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = OrlojClockLocation.prague.timeZone
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = OrlojClockLocation.prague.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = minutes / 60
        components.minute = minutes % 60

        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
