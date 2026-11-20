import Foundation
import SwiftUI
import Testing
@testable import astologia_hologia

/// The dial hangs on a wall facing the equator, as the Orloj does on the
/// Old Town Hall's south wall; shadows follow the Sun across it.
struct OrlojDialLightingTests {
    @Test func noonShadowsFallStraightDownAndLengthenWithTheSummerSun() {
        let winter = OrlojDialLighting(sunAltitudeDegrees: 16.5, sunAzimuthDegrees: 180, latitudeDegrees: 50.09)
        let summer = OrlojDialLighting(sunAltitudeDegrees: 63.3, sunAzimuthDegrees: 180, latitudeDegrees: 50.09)
        for light in [winter, summer] {
            #expect(light.sunlit > 0.99)
            #expect(abs(light.shadowShift.width) < 0.001)
            #expect(light.shadowShift.height > 0)
        }
        // On a vertical wall the shadow length per unit of relief is tan(altitude).
        #expect(abs(winter.shadowShift.height - tan(16.5 * .pi / 180)) < 0.01)
        #expect(abs(summer.shadowShift.height - tan(63.3 * .pi / 180)) < 0.01)
    }

    @Test func morningAndAfternoonShadowsSwingAcrossTheFace() {
        // Facing the south wall, east is on the viewer's right.
        let morning = OrlojDialLighting(sunAltitudeDegrees: 30, sunAzimuthDegrees: 130, latitudeDegrees: 50.09)
        let afternoon = OrlojDialLighting(sunAltitudeDegrees: 30, sunAzimuthDegrees: 230, latitudeDegrees: 50.09)
        #expect(morning.shadowShift.width < 0)
        #expect(afternoon.shadowShift.width > 0)
        #expect(morning.lightDirection.width > 0)
        #expect(afternoon.lightDirection.width < 0)
    }

    @Test func sunBehindTheWallOrBelowTheHorizonLeavesOnlySoftSkylight() {
        let summerEvening = OrlojDialLighting(sunAltitudeDegrees: 8, sunAzimuthDegrees: 295, latitudeDegrees: 50.09)
        let night = OrlojDialLighting(sunAltitudeDegrees: -30, sunAzimuthDegrees: 0, latitudeDegrees: 50.09)
        for light in [summerEvening, night] {
            #expect(light.sunlit < 0.01)
            #expect(light.shadowSoftness > 0.99)
            #expect(light.warmth < 0.01)
            #expect(abs(light.shadowShift.width) < 0.001)
        }
        #expect(summerEvening.daylight > 0.99)
        #expect(night.daylight < 0.01)
    }

    @Test func lowSunReachingTheFaceIsWarm() {
        let lowSun = OrlojDialLighting(sunAltitudeDegrees: 6, sunAzimuthDegrees: 210, latitudeDegrees: 50.09)
        let highSun = OrlojDialLighting(sunAltitudeDegrees: 45, sunAzimuthDegrees: 180, latitudeDegrees: 50.09)
        #expect(lowSun.warmth > 0.5)
        #expect(highSun.warmth < 0.01)
    }

    @Test func southernDialFacesNorth() {
        let sydneyNoon = OrlojDialLighting(sunAltitudeDegrees: 40, sunAzimuthDegrees: 0, latitudeDegrees: -33.87)
        #expect(sydneyNoon.sunlit > 0.99)
        #expect(abs(sydneyNoon.shadowShift.width) < 0.001)
        #expect(sydneyNoon.shadowShift.height > 0)
    }

    @Test func grazingLightKeepsShadowsOnTheFace() {
        let grazing = OrlojDialLighting(sunAltitudeDegrees: 20, sunAzimuthDegrees: 97, latitudeDegrees: 50.09)
        #expect(hypot(grazing.shadowShift.width, grazing.shadowShift.height) <= 2.6 + 1e-9)
    }

    @Test func localFrameRotationRoundTrips() {
        let light = OrlojDialLighting(sunAltitudeDegrees: 30, sunAzimuthDegrees: 230, latitudeDegrees: 50.09)
        let local = light.rotatedForLocalFrame(degrees: 90)
        // A context rotated 90° clockwise maps local (x, y) to screen (-y, x).
        #expect(abs(-local.lightDirection.height - light.lightDirection.width) < 1e-9)
        #expect(abs(local.lightDirection.width - light.lightDirection.height) < 1e-9)
    }

    @Test func pragueStateProducesLightFromTheModelSun() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-06-21T13:00:00+02:00"))
        let state = OrlojCalculator.state(for: date, location: .prague)
        let light = OrlojClockView(state: state).lighting
        #expect(state.solar.altitudeDegrees > 55)
        #expect(light.sunlit > 0.99)
        #expect(light.shadowShift.height > 1.4)
    }
}
