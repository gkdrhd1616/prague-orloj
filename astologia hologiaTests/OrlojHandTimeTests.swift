import Foundation
import SwiftUI
import Testing
@testable import astologia_hologia

struct OrlojHandTimeTests {
    init() {
        OrlojLocalization.useSourceLanguageForTests()
    }

    @Test func seoulGoldenHandAtCivilNoonAgreesWithIndependentSolarTime() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-11-20T12:00:00+09:00"))
        let state = OrlojCalculator.state(for: date, location: .seoul)
        // Independent reference at longitude 126.978° E, from the US Naval
        // Observatory's equation of time: https://aa.usno.navy.mil/faq/sun_approx
        // EoT +14.481 min; 12:00 KST + 4(126.978 − 135) + EoT = 11:42:23.6.
        let referenceSeconds = 11 * 3600.0 + 42 * 60 + 23.6
        let secondsFromHand = secondsOnRomanRing(state)
        #expect(abs(secondsFromHand - referenceSeconds) < 5)
        #expect(abs(state.solar.apparentSolarMinutes * 60 - secondsFromHand) < 0.001)
        #expect(state.dialTimeString == "11:42")
        #expect(state.localComponents.hour == 12 && state.localComponents.minute == 0)
        let readout = OrlojAstronomyReadout(state: state)
        #expect(readout.primaryMetrics.contains { $0.title == "Apparent solar time" && $0.value == "11:42 solar" })
        #expect(readout.primaryMetrics.contains { $0.title == "Local time" && $0.value == state.localTimeString })
    }

    @Test func pragueGoldenHandAtCivilNoonShowsWinterAndSummerCET() throws {
        for (instant, expectedHour) in [("2026-11-20T12:00:00+01:00", 12), ("2026-06-21T12:00:00+02:00", 11)] {
            let date = try #require(ISO8601DateFormatter().date(from: instant))
            let state = OrlojCalculator.state(for: date, location: .prague)
            #expect(abs(secondsOnRomanRing(state) - Double(expectedHour) * 3600) < 0.001)
            #expect(state.dialTimeZoneLabel == "CET")
            #expect(state.localComponents.hour == 12 && state.localComponents.minute == 0)
        }
    }

    private func secondsOnRomanRing(_ state: OrlojClockState) -> Double {
        let angle = OrlojClockView(state: state).goldenHandAngle.degrees
        return (angle + 180).truncatingRemainder(dividingBy: 360) * 240
    }
}
