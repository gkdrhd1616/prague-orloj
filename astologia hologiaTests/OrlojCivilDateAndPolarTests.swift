import Foundation
import Testing
@testable import astologia_hologia

struct OrlojCivilDateAndPolarTests {
    @Test func apiaDaylightUsesItsOwnCivilDateAcrossTheDateLine() throws {
        let zone = try #require(TimeZone(identifier: "Pacific/Apia"))
        let date = try #require(ISO8601DateFormatter().date(from: "2026-06-21T12:00:00+13:00"))
        let state = OrlojCalculator.state(for: date, coordinates: .init(latitude: -13.83, longitude: -171.75), timeZone: zone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        for event in [state.daylightWindow, state.twilightWindow] {
            let start = try #require(event.startDate)
            let end = try #require(event.endDate)
            #expect(calendar.isDate(start, inSameDayAs: date))
            #expect(calendar.isDate(end, inSameDayAs: date))
            #expect(start < date && date < end)
        }
        #expect(state.babylonianHour != nil)
        #expect((0.35...0.65).contains(state.daylightProgress))
    }

    @Test func solarNoonNearUtcMidnightCanSpanTwoCivilDates() throws {
        let coords = OrlojCoordinates(latitude: 20, longitude: 180)
        for instant in ["2026-06-21T01:00:00Z", "2026-06-21T23:00:00Z"] {
            let date = try #require(ISO8601DateFormatter().date(from: instant))
            let state = OrlojCalculator.state(for: date, coordinates: coords, timeZone: .gmt)
            #expect(state.solar.altitudeDegrees > 0)
            #expect(state.babylonianHour != nil)
        }
    }

    @Test func polarSunUsesMeasuredLatitudeWithoutInventingDailyCrossings() throws {
        let coordinates = OrlojCoordinates(latitude: 69.65, longitude: 18.955)
        let zone = try #require(TimeZone(identifier: "Europe/Oslo"))
        for (instant, kind) in [("2026-06-21T00:00:00+02:00", OrlojSolarWindowKind.alwaysAbove),
                                ("2026-12-21T12:00:00+01:00", .alwaysBelow)] {
            let date = try #require(ISO8601DateFormatter().date(from: instant))
            let state = OrlojCalculator.state(for: date, coordinates: coordinates, timeZone: zone)
            #expect(state.location.coordinates == coordinates)
            #expect(state.daylightWindow.kind == kind)
            #expect(state.daylightWindow.startDate == nil && state.daylightWindow.endDate == nil)
            #expect(state.oldCzechHour == nil && state.babylonianHour == nil)
            #expect(state.sunriseTimeString == "—" && state.sunsetTimeString == "—")
            #expect((state.solar.altitudeDegrees > 0) == (kind == .alwaysAbove))
            #expect(state.babylonianHourLabel == (kind == .alwaysAbove ? "Polar day" : "Night"))
        }
    }
}
