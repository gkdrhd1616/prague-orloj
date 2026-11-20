//
//  OrlojClockView.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import SwiftUI

struct OrlojClockView: View {
    let state: OrlojClockState
    var dialFocus: OrlojDialFocusState = .display
    var compact = false

    var goldenHandAngle: Angle {
        let point = state.dialSunProjection
        return .radians(atan2(point.x, point.y))
    }

    var body: some View {
        Canvas { context, size in
            drawDial(in: &context, size: size)
        }
        .drawingGroup()
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Prague Orloj astronomical dial")
        .accessibilityIdentifier("orlojDial")
        .accessibilityValue("\(state.dialTimeString) \(state.dialTimeZoneLabel), \(state.skyPhaseLabel), \(state.dialZodiacSign.name), \(state.lunar.phaseName)")
    }

    private func drawDial(in context: inout GraphicsContext, size: CGSize) {
        let geometry = OrlojDialGeometry(size: size)

        // 1. Outer dark/vignette field
        drawOuterField(in: &context, geometry: geometry)

        // 2. Fixed painted astronomical plate
        drawProjectedSky(in: &context, geometry: geometry)

        // 3. Fixed background structural linework
        drawProjectionGuides(in: &context, geometry: geometry)
        drawUnequalHourCurves(in: &context, geometry: geometry)

        // 4. Latin inscriptions
        drawLatinLabels(in: &context, geometry: geometry)

        drawFixedEarth(in: &context, geometry: geometry)

        // 5. Fixed ordinary time markings
        drawFixedRomanScale(in: &context, geometry: geometry)
        drawOldCzechRing(in: &context, geometry: geometry)

        // 6-7. Moving zodiac and astronomical bodies
        drawProjectedZodiac(in: &context, geometry: geometry)
        drawSun(in: &context, geometry: geometry)
        drawMoon(in: &context, geometry: geometry)

        // 8. Foreground outer ring and central cap
        drawAxle(in: &context, geometry: geometry)

        // 9. Debug and guide overlays, only when the current mode requests them
        drawInterpretiveOverlay(in: &context, geometry: geometry)
        drawGuideReadingOverlay(in: &context, geometry: geometry)
    }

    private func drawOuterField(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        context.fill(Path(CGRect(origin: .zero, size: geometry.size)), with: .color(OrlojDesignSystem.background))
        context.fill(circle(center: geometry.center, radius: geometry.radius), with: .radialGradient(
            Gradient(colors: [
                OrlojDesignSystem.stone.opacity(0.78),
                OrlojDesignSystem.shadowBrown.opacity(0.88),
                OrlojDesignSystem.stoneDeep.opacity(0.98)
            ]),
            center: CGPoint(x: geometry.center.x - geometry.radius * 0.12, y: geometry.center.y - geometry.radius * 0.16),
            startRadius: geometry.radius * 0.12,
            endRadius: geometry.radius
        ))
        drawMetalAnnulus(
            center: geometry.center,
            innerRadius: geometry.oldCzechOuterRadius * 0.992,
            outerRadius: geometry.radius,
            in: &context,
            base: OrlojDesignSystem.darkBrass,
            alpha: 0.78
        )
        context.stroke(circle(center: geometry.center, radius: geometry.radius * 0.998), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.86)), lineWidth: geometry.radius * 0.012)
        context.stroke(circle(center: geometry.center, radius: geometry.radius * 0.994), with: .color(OrlojDesignSystem.highlightGold.opacity(0.32)), lineWidth: geometry.radius * 0.004)
        context.stroke(circle(center: geometry.center, radius: geometry.radius * 0.958), with: .color(OrlojDesignSystem.ink.opacity(0.76)), lineWidth: geometry.radius * 0.006)
        drawOuterBeadedFrame(in: &context, geometry: geometry)
        drawAgedMetalWear(in: &context, geometry: geometry)
    }

    private func drawProjectedSky(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        // Fixed Orloj plate: these painted regions come from projection geometry, not daily sunrise/sunset wedges.
        let disk = circle(center: geometry.center, radius: geometry.coloredPlateRadius)
        let horizon = OrlojProjection.constantAltitudeBoundary(
            latitudeDegrees: state.location.coordinates.latitude,
            altitudeDegrees: 0
        )
        let night = OrlojProjection.constantAltitudeBoundary(
            latitudeDegrees: state.location.coordinates.latitude,
            altitudeDegrees: -18
        )

        var clipped = context
        clipped.clip(to: disk)
        clipped.fill(disk, with: .color(OrlojDesignSystem.plateNight))
        clipped.fill(boundaryLowerRegionPath(horizon, geometry: geometry), with: .color(OrlojDesignSystem.plateTwilight.opacity(0.92)), style: FillStyle(eoFill: true))
        clipped.fill(boundaryLowerRegionPath(horizon, geometry: geometry), with: .color(OrlojDesignSystem.burntUmber.opacity(0.12)), style: FillStyle(eoFill: true))
        clipped.fill(boundaryLowerRegionPath(night, geometry: geometry), with: .color(OrlojDesignSystem.plateNight.opacity(0.98)), style: FillStyle(eoFill: true))

        let dayPath = dayRegionPath(horizon, plateRect: geometry.coloredPlateRect, geometry: geometry)
        clipped.fill(dayPath, with: .color(OrlojDesignSystem.plateDay.opacity(0.94)), style: FillStyle(eoFill: true))
        clipped.fill(dayPath, with: .color(OrlojDesignSystem.verdigris.opacity(0.035)), style: FillStyle(eoFill: true))
        clipped.fill(dayPath, with: .color(OrlojDesignSystem.ivoryText.opacity(0.006)), style: FillStyle(eoFill: true))
        // The real plate has clean painted regions, not concentric gradient bands.
        drawPaintedPatina(in: &clipped, geometry: geometry)

        clipped.stroke(disk, with: .color(OrlojDesignSystem.shadowBrown.opacity(0.78)), lineWidth: geometry.radius * 0.011)
        clipped.stroke(disk, with: .color(OrlojDesignSystem.gold.opacity(0.72)), lineWidth: geometry.radius * 0.0055)
        clipped.stroke(disk, with: .color(OrlojDesignSystem.highlightGold.opacity(0.5)), lineWidth: geometry.radius * 0.0018)
        clipped.stroke(boundaryStrokePath(horizon, geometry: geometry), with: .color(OrlojDesignSystem.gold.opacity(0.66)), lineWidth: geometry.radius * 0.0036)

    }

    private func drawProjectionGuides(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let alpha = showsDebugProjectionHelpers || showsGuideTropicHighlight ? 0.95 : 0.78
        let obliquity = OrlojCalculator.degreesToRadians(state.solar.obliquityDegrees)
        let equator = geometry.screenLength(1)
        let cancer = geometry.screenLength(tan(.pi / 4 + obliquity / 2))
        let capricorn = geometry.screenLength(tan(.pi / 4 - obliquity / 2))

        // These three gold circles are permanent parts of the physical astrolabe.
        for radius in [cancer, equator, capricorn] {
            context.stroke(circle(center: geometry.center, radius: radius), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.55 * alpha)), lineWidth: geometry.radius * 0.005)
            context.stroke(circle(center: geometry.center, radius: radius), with: .color(OrlojDesignSystem.gold.opacity(alpha)), lineWidth: geometry.radius * 0.003)
        }

        if showsDebugProjectionHelpers {
            drawSmallLabel("TROPIC CANCER", at: CGPoint(x: geometry.center.x, y: geometry.center.y - cancer), in: &context, geometry: geometry, color: OrlojDesignSystem.verdigris.opacity(0.78))
            drawSmallLabel("EQUATOR", at: CGPoint(x: geometry.center.x - equator * 0.7, y: geometry.center.y), in: &context, geometry: geometry, color: OrlojDesignSystem.ivoryText.opacity(0.78))
            drawSmallLabel("TROPIC CAPRICORN", at: CGPoint(x: geometry.center.x, y: geometry.center.y + capricorn), in: &context, geometry: geometry, color: OrlojDesignSystem.verdigris.opacity(0.78))
        }
    }

    private func drawFixedRomanScale(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let alpha = layerAlpha(.timeRings, representedLayers: [.romanTimeRing, .romanNumerals, .civilHourTicks])
        context.stroke(circle(center: geometry.center, radius: geometry.romanRadius + geometry.radius * 0.047), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.32 * alpha)), lineWidth: geometry.radius * 0.006)
        context.stroke(circle(center: geometry.center, radius: geometry.romanRadius + geometry.radius * 0.044), with: .color(OrlojDesignSystem.gold.opacity(0.68 * alpha)), lineWidth: geometry.radius * 0.0034)
        context.stroke(circle(center: geometry.center, radius: geometry.romanRadius - geometry.radius * 0.06), with: .color(OrlojDesignSystem.ink.opacity(0.34 * alpha)), lineWidth: geometry.radius * 0.004)
        context.stroke(circle(center: geometry.center, radius: geometry.romanRadius - geometry.radius * 0.064), with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.12 * alpha)), lineWidth: geometry.radius * 0.0018)

        // The historical scale uses the applied numerals themselves. The former
        // generic 96 short ticks competed with the long stems of the numerals.
        for hour in 1...24 {
            let degrees = OrlojCalculator.orlojAngle(forLocalHour: Double(hour))
            let point = geometry.polarPoint(radius: geometry.romanRadius, degrees: degrees)
            OrlojRomanNumerals.draw(romanNumeral(for: hour), at: point, height: geometry.radius * 0.094,
                rotationDegrees: degrees, in: &context, alpha: alpha)
        }
    }

    private func drawUnequalHourCurves(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let alpha = layerAlpha(.unequalHours, representedLayers: [.unequalHourLines, .daylightHourCurves])
        guard alpha > 0.05 else {
            return
        }

        let horizon = OrlojProjection.constantAltitudeBoundary(
            latitudeDegrees: state.location.coordinates.latitude,
            altitudeDegrees: 0
        )
        let isFocused = dialFocus.focus == .unequalHours || currentGuideLayers.containsAny(.unequalHourLines, .daylightHourCurves)
        let lineAlpha = alpha * (isFocused ? 1 : 0.88)

        let fixedPlateClip = circle(center: geometry.center, radius: geometry.coloredPlateRadius)
        let dayClip = dayRegionPath(horizon, plateRect: geometry.coloredPlateRect, geometry: geometry)
        let romanFadeRadius = geometry.romanRadius - geometry.radius * 0.095
        let romanFieldClip = annulusPath(
            center: geometry.center,
            innerRadius: romanFadeRadius,
            outerRadius: geometry.coloredPlateRadius
        )
        var mutedPlateContext = context
        mutedPlateContext.clip(to: fixedPlateClip)
        var innerDayContext = context
        innerDayContext.clip(to: circle(center: geometry.center, radius: romanFadeRadius))
        innerDayContext.clip(
            to: dayClip,
            style: FillStyle(eoFill: true)
        )
        var romanDayContext = context
        romanDayContext.clip(to: romanFieldClip, style: FillStyle(eoFill: true))
        romanDayContext.clip(
            to: dayClip,
            style: FillStyle(eoFill: true)
        )
        for samples in state.unequalHourBoundaries {
            // Draw only the sampled unequal-hour curve. Do not extend endpoints with straight
            // construction rays. A very quiet plate pass lets twilight/night absorb the curve,
            // while the blue/day clip carries the visible daylight division. The Roman band gets
            // a softer pass so numerals remain the dominant foreground inscription.
            let path = projectedHourArcPath(samples: samples, geometry: geometry)
            mutedPlateContext.stroke(
                path,
                with: .color(OrlojDesignSystem.shadowBrown.opacity(0.28 * lineAlpha)),
                style: StrokeStyle(lineWidth: geometry.radius * 0.0038, lineCap: .round, lineJoin: .round)
            )
            mutedPlateContext.stroke(
                path,
                with: .color(OrlojDesignSystem.gold.opacity(0.28 * lineAlpha)),
                style: StrokeStyle(lineWidth: geometry.radius * 0.0017, lineCap: .round, lineJoin: .round)
            )
            innerDayContext.stroke(
                path,
                with: .color(OrlojDesignSystem.shadowBrown.opacity(0.4 * lineAlpha)),
                style: StrokeStyle(lineWidth: geometry.radius * 0.0042, lineCap: .round, lineJoin: .round)
            )
            innerDayContext.stroke(
                path,
                with: .color(OrlojDesignSystem.highlightGold.opacity(0.62 * lineAlpha)),
                style: StrokeStyle(lineWidth: geometry.radius * 0.0019, lineCap: .round, lineJoin: .round)
            )
            romanDayContext.stroke(
                path,
                with: .color(OrlojDesignSystem.shadowBrown.opacity(0.2 * lineAlpha)),
                style: StrokeStyle(lineWidth: geometry.radius * 0.0024, lineCap: .round, lineJoin: .round)
            )
            romanDayContext.stroke(
                path,
                with: .color(OrlojDesignSystem.gold.opacity(0.34 * lineAlpha)),
                style: StrokeStyle(lineWidth: geometry.radius * 0.0012, lineCap: .round, lineJoin: .round)
            )
        }

        let labelPositions = OrlojCalculator.unequalHourLabelPositions(
            latitudeDegrees: state.location.coordinates.latitude
        )
        for (index, point) in labelPositions.enumerated() {
            drawText(
                "\(index + 1)",
                at: geometry.screenPoint(point),
                in: &context,
                size: geometry.radius * 0.052,
                weight: .semibold,
                design: .serif,
                color: OrlojDesignSystem.ink.opacity(0.96 * alpha)
            )
        }
    }

    private func projectedHourArcPath(
        samples: [OrlojProjectionPoint],
        geometry: OrlojDialGeometry
    ) -> Path {
        let points = samples
            .map { geometry.screenPoint($0) }
            .filter { $0.x.isFinite && $0.y.isFinite }
        var path = Path()
        guard let first = points.first else {
            return path
        }

        path.move(to: first)

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        return path
    }

    private func drawProjectedZodiac(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let alpha = layerAlpha(.zodiac, representedLayers: [.zodiacRing, .zodiacGlyphs, .eclipticPath, .solarLongitudePoint, .eclipticPosition, .ariesStar, .zodiacZeroPoint])
        let track = eclipticCircle(geometry: geometry)
        // The painted signs sit inside the ladder. The ladder itself is the
        // projected ecliptic and remains tangent to the two tropic circles.
        let eclipticPath = circle(center: track.center, radius: track.radius - geometry.radius * 0.083)

        var castShadow = context
        castShadow.translateBy(x: geometry.radius * 0.003, y: geometry.radius * 0.007)
        castShadow.stroke(eclipticPath, with: .color(.black.opacity(0.30 * alpha)), lineWidth: geometry.radius * 0.146)
        var gildedBand = context
        gildedBand.opacity *= alpha
        gildedBand.stroke(eclipticPath, with: OrlojDialMaterials.gilding(in: eclipticPath.boundingRect),
            lineWidth: geometry.radius * 0.13)
        context.stroke(eclipticPath, with: .color(OrlojDesignSystem.zodiacBlue.opacity(0.98 * alpha)),
            lineWidth: geometry.radius * 0.112)
        var enamel = context
        enamel.opacity *= alpha
        enamel.clip(to: eclipticPath.strokedPath(StrokeStyle(lineWidth: geometry.radius * 0.112)))
        OrlojDialMaterials.paintedSurface(in: &enamel, bounds: eclipticPath.boundingRect.insetBy(dx: -geometry.radius * 0.06, dy: -geometry.radius * 0.06), strength: 0.7)
        drawEclipticLadder(in: &context, geometry: geometry, alpha: alpha)

        for boundary in stride(from: 0.0, to: 360.0, by: 30.0) {
            drawEclipticSeparator(longitude: boundary, in: &context, geometry: geometry, alpha: alpha)
        }

        for (index, sign) in ZodiacSign.all.enumerated() {
            let longitude = Double(index) * 30 + 15
            let point = zodiacBandPoint(longitude: longitude, geometry: geometry)
            let isCurrent = sign.id == state.dialZodiacSign.id
            drawZodiacGlyph(sign, at: point, longitude: longitude, isCurrent: isCurrent, in: &context, geometry: geometry, alpha: alpha)
        }

        let ariesPoint = ariesStarPoint(geometry: geometry)
        drawLine(from: geometry.center, to: ariesPoint, in: &context, color: OrlojDesignSystem.darkBrass.opacity(0.8 * alpha), lineWidth: geometry.radius * 0.006)
        drawLine(from: geometry.center, to: ariesPoint, in: &context, color: OrlojDesignSystem.highlightGold.opacity(0.9 * alpha), lineWidth: geometry.radius * 0.0025)
        context.fill(starPath(center: ariesPoint, outerRadius: geometry.radius * 0.025, innerRadius: geometry.radius * 0.009), with: .color(OrlojDesignSystem.highlightGold.opacity(0.84 * alpha)))
        context.stroke(starPath(center: ariesPoint, outerRadius: geometry.radius * 0.026, innerRadius: geometry.radius * 0.0095), with: .color(OrlojDesignSystem.ink.opacity(0.55 * alpha)), lineWidth: geometry.radius * 0.002)
        if showsDebugProjectionHelpers {
            drawSmallLabel("ARIES 1ST", at: CGPoint(x: ariesPoint.x, y: ariesPoint.y - geometry.radius * 0.045), in: &context, geometry: geometry, color: OrlojDesignSystem.highlightGold.opacity(0.86))
        }
    }

    private func drawSun(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let alpha = sunAlpha()
        let sunPoint = geometry.screenPoint(state.dialSunProjection)
        let handEnd = geometry.polarPoint(radius: geometry.oldCzechInnerRadius, degrees: goldenHandAngle.degrees)

        drawLine(
            from: geometry.center,
            to: handEnd,
            in: &context,
            color: OrlojDesignSystem.shadowBrown.opacity(0.72 * alpha),
            lineWidth: geometry.radius * 0.014
        )
        drawLine(
            from: geometry.center,
            to: handEnd,
            in: &context,
            color: OrlojDesignSystem.darkBrass.opacity(0.84 * alpha),
            lineWidth: geometry.radius * 0.0105
        )
        drawLine(
            from: geometry.center,
            to: handEnd,
            in: &context,
            color: OrlojDesignSystem.gold.opacity(0.92 * alpha),
            lineWidth: geometry.radius * 0.0075
        )
        drawLine(
            from: geometry.center,
            to: handEnd,
            in: &context,
            color: OrlojDesignSystem.highlightGold.opacity(0.72 * alpha),
            lineWidth: geometry.radius * 0.0022
        )
        context.fill(circle(center: sunPoint, radius: geometry.radius * 0.031), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.62 * alpha)))
        context.stroke(circle(center: sunPoint, radius: geometry.radius * 0.034), with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.42 * alpha)), lineWidth: geometry.radius * 0.003)
        drawGoldenHand(in: &context, geometry: geometry, alpha: alpha)
        drawSunIcon(at: sunPoint, radius: geometry.radius * 0.03, in: &context, alpha: alpha)
    }

    private func drawGoldenHand(in context: inout GraphicsContext, geometry: OrlojDialGeometry, alpha: Double) {
        var handContext = context
        handContext.translateBy(x: geometry.center.x, y: geometry.center.y)
        handContext.rotate(by: goldenHandAngle)
        handContext.scaleBy(x: geometry.radius, y: geometry.radius)

        OrlojSolarOrnaments.hand(in: &handContext, alpha: alpha)
    }

    private func drawEclipticLadder(in context: inout GraphicsContext, geometry: OrlojDialGeometry, alpha: Double) {
        let track = eclipticCircle(geometry: geometry)
        let center = track.center
        let trackRadius = track.radius
        let innerRadius = trackRadius - geometry.radius * 0.024
        let outerRadius = trackRadius
        for radius in [innerRadius, outerRadius] {
            let rim = circle(center: center, radius: radius)
            OrlojDialMaterials.raisedRim(rim, in: &context, bounds: rim.boundingRect,
                width: geometry.radius * 0.0045, alpha: alpha)
        }
        for longitude in stride(from: 0.0, to: 360.0, by: 5.0) {
            let point = projectedEclipticPoint(longitude: longitude, geometry: geometry)
            let dx = (point.x - center.x) / trackRadius
            let dy = (point.y - center.y) / trackRadius
            drawLine(
                from: CGPoint(x: center.x + dx * innerRadius, y: center.y + dy * innerRadius),
                to: CGPoint(x: center.x + dx * outerRadius, y: center.y + dy * outerRadius),
                in: &context, color: OrlojDesignSystem.highlightGold.opacity(0.9 * alpha),
                lineWidth: geometry.radius * (Int(longitude).isMultiple(of: 30) ? 0.005 : 0.003)
            )
        }
    }

    private func eclipticCircle(geometry: OrlojDialGeometry) -> (center: CGPoint, radius: CGFloat) {
        let north = projectedEclipticPoint(longitude: 90, geometry: geometry)
        let south = projectedEclipticPoint(longitude: 270, geometry: geometry)
        return (CGPoint(x: (north.x + south.x) / 2, y: (north.y + south.y) / 2), hypot(north.x - south.x, north.y - south.y) / 2)
    }

    private func zodiacBandPoint(longitude: Double, geometry: OrlojDialGeometry) -> CGPoint {
        let point = projectedEclipticPoint(longitude: longitude, geometry: geometry)
        let track = eclipticCircle(geometry: geometry)
        let scale = (track.radius - geometry.radius * 0.083) / track.radius
        return CGPoint(x: track.center.x + (point.x - track.center.x) * scale, y: track.center.y + (point.y - track.center.y) * scale)
    }

    private func ariesStarPoint(geometry: OrlojDialGeometry) -> CGPoint {
        geometry.extendedRadialPoint(through: geometry.screenPoint(state.ariesProjection), radius: geometry.romanRadius - geometry.radius * 0.085)
    }

    private func drawMoon(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let alpha = layerAlpha(.moon, representedLayers: [.moonMarker, .moonPhase, .lunarPosition])
        let moonPoint = geometry.screenPoint(state.dialMoonProjection)

        drawLine(
            from: geometry.center,
            to: moonPoint,
            in: &context,
            color: OrlojDesignSystem.shadowBrown.opacity(0.5 * alpha),
            lineWidth: geometry.radius * 0.0065
        )
        drawLine(
            from: geometry.center,
            to: moonPoint,
            in: &context,
            color: OrlojDesignSystem.darkBrass.opacity(0.44 * alpha),
            lineWidth: geometry.radius * 0.0042
        )
        drawLine(
            from: geometry.center,
            to: moonPoint,
            in: &context,
            color: OrlojDesignSystem.ivoryText.opacity(0.24 * alpha),
            lineWidth: geometry.radius * 0.0016
        )
        drawMoonIcon(at: moonPoint, radius: geometry.radius * (130.0 / 3000.0), in: &context, alpha: alpha,
            supportAngleRadians: Double(atan2(moonPoint.x - geometry.center.x, geometry.center.y - moonPoint.y)))
    }

    private func drawOldCzechRing(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let alpha = layerAlpha(.timeRings, representedLayers: [.oldCzechRing, .outer24Numerals, .sunsetAlignmentMarker])
        let ring = annulusPath(
            center: geometry.center,
            innerRadius: geometry.oldCzechInnerRadius,
            outerRadius: geometry.oldCzechOuterRadius
        )
        context.fill(ring, with: .color(OrlojDesignSystem.enamelBlueBlack.opacity(0.98 * alpha)), style: FillStyle(eoFill: true))
        context.fill(ring, with: .color(OrlojDesignSystem.ink.opacity(0.24 * alpha)), style: FillStyle(eoFill: true))
        var enamel = context
        enamel.clip(to: ring, style: FillStyle(eoFill: true))
        enamel.opacity *= alpha
        OrlojDialMaterials.paintedSurface(in: &enamel,
            bounds: circle(center: geometry.center, radius: geometry.oldCzechOuterRadius).boundingRect, strength: 0.8)
        context.stroke(circle(center: geometry.center, radius: geometry.oldCzechOuterRadius), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.9 * alpha)), lineWidth: geometry.radius * 0.011)
        context.stroke(circle(center: geometry.center, radius: geometry.oldCzechOuterRadius - geometry.radius * 0.006), with: .color(OrlojDesignSystem.gold.opacity(0.94 * alpha)), lineWidth: geometry.radius * 0.0055)
        context.stroke(circle(center: geometry.center, radius: geometry.oldCzechOuterRadius - geometry.radius * 0.011), with: .color(OrlojDesignSystem.highlightGold.opacity(0.55 * alpha)), lineWidth: geometry.radius * 0.0018)
        context.stroke(circle(center: geometry.center, radius: geometry.oldCzechInnerRadius + geometry.radius * 0.006), with: .color(OrlojDesignSystem.gold.opacity(0.9 * alpha)), lineWidth: geometry.radius * 0.005)
        context.stroke(circle(center: geometry.center, radius: geometry.oldCzechInnerRadius), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.8 * alpha)), lineWidth: geometry.radius * 0.007)

        for radius in [geometry.oldCzechInnerRadius + geometry.radius * 0.004, geometry.oldCzechOuterRadius - geometry.radius * 0.006] {
            let rim = circle(center: geometry.center, radius: radius)
            OrlojDialMaterials.raisedRim(rim, in: &context, bounds: rim.boundingRect,
                width: geometry.radius * 0.006, alpha: alpha)
        }

        // A sunset-aligned scale has no reading during polar day or night.
        guard state.daylightWindow.kind == .normal else { return }
        for tick in 0..<96 {
            let degrees = state.sunsetAngleDegrees + Double(tick) * 3.75
            let isHour = tick % 4 == 0
            let inner = geometry.oldCzechInnerRadius + geometry.radius * (isHour ? 0.012 : 0.024)
            let outer = geometry.oldCzechOuterRadius - geometry.radius * (isHour ? 0.011 : 0.018)
            if isHour {
                drawLine(
                    from: geometry.polarPoint(radius: inner - geometry.radius * 0.003, degrees: degrees),
                    to: geometry.polarPoint(radius: outer + geometry.radius * 0.002, degrees: degrees),
                    in: &context,
                    color: OrlojDesignSystem.shadowBrown.opacity(0.72 * alpha),
                    lineWidth: geometry.radius * 0.0042
                )
                drawLine(
                    from: geometry.polarPoint(radius: inner, degrees: degrees),
                    to: geometry.polarPoint(radius: outer, degrees: degrees),
                    in: &context,
                    color: OrlojDesignSystem.agedGoldEdge.opacity(0.42 * alpha),
                    lineWidth: geometry.radius * 0.0018
                )
            } else {
                drawLine(
                    from: geometry.polarPoint(radius: inner, degrees: degrees),
                    to: geometry.polarPoint(radius: outer, degrees: degrees),
                    in: &context,
                    color: OrlojDesignSystem.darkBrass.opacity(0.18 * alpha),
                    lineWidth: geometry.radius * 0.001
                )
            }
        }

        var numerals = context
        numerals.translateBy(x: geometry.center.x, y: geometry.center.y)
        numerals.rotate(by: .degrees(state.sunsetAngleDegrees))
        numerals.opacity *= alpha
        let imageRadius = geometry.oldCzechLabelRadius / 0.925
        let numeralImage = numerals.resolve(Image("refined_czech_numerals").renderingMode(.original))
        numerals.draw(numeralImage, in: CGRect(x: -imageRadius, y: -imageRadius, width: imageRadius * 2, height: imageRadius * 2))

        let sunsetPoint = geometry.polarPoint(radius: geometry.oldCzechInnerRadius, degrees: state.sunsetAngleDegrees)
        drawLine(
            from: geometry.polarPoint(radius: geometry.oldCzechOuterRadius, degrees: state.sunsetAngleDegrees),
            to: sunsetPoint,
            in: &context,
            color: OrlojDesignSystem.highlightGold.opacity(0.86 * alpha),
            lineWidth: geometry.radius * 0.007
        )
        context.stroke(circle(center: sunsetPoint, radius: geometry.radius * 0.014), with: .color(OrlojDesignSystem.highlightGold.opacity(0.62 * alpha)), lineWidth: geometry.radius * 0.003)
    }

    private func drawFixedEarth(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        // 2019 restoration reference: a blue globe with curved gold graticule.
        // Historical dimensions give globe/equator radii of 36 cm / 82.5 cm.
        OrlojEarthRenderer.draw(center: geometry.center, radius: geometry.screenLength(1) * (36.0 / 82.5), in: &context)
    }

    private func drawAxle(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        context.fill(circle(center: geometry.center, radius: geometry.radius * 0.018), with: .color(OrlojDesignSystem.ink))
        context.fill(circle(center: geometry.center, radius: geometry.radius * 0.011), with: .color(OrlojDesignSystem.gold))
        context.stroke(circle(center: geometry.center, radius: geometry.radius * 0.011), with: .color(OrlojDesignSystem.highlightGold.opacity(0.7)), lineWidth: geometry.radius * 0.002)
    }

    private func drawInterpretiveOverlay(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        guard showsDebugProjectionHelpers else {
            return
        }

        let horizon = OrlojProjection.constantAltitudeBoundary(latitudeDegrees: state.location.coordinates.latitude, altitudeDegrees: 0)
        let night = OrlojProjection.constantAltitudeBoundary(latitudeDegrees: state.location.coordinates.latitude, altitudeDegrees: -18)
        context.stroke(boundaryStrokePath(horizon, geometry: geometry), with: .color(OrlojDesignSystem.ivoryText.opacity(0.48)), style: StrokeStyle(lineWidth: geometry.radius * 0.004, dash: [6, 5]))
        drawSmallLabel("HORIZON", at: CGPoint(x: geometry.center.x + geometry.astrolabeRadius * 0.42, y: geometry.center.y + geometry.astrolabeRadius * 0.26), in: &context, geometry: geometry, color: OrlojDesignSystem.ivoryText.opacity(0.86))
        context.stroke(boundaryStrokePath(night, geometry: geometry), with: .color(OrlojDesignSystem.copper.opacity(0.62)), style: StrokeStyle(lineWidth: geometry.radius * 0.004, dash: [5, 5]))
        drawSmallLabel("-18 NIGHT", at: CGPoint(x: geometry.center.x + geometry.astrolabeRadius * 0.36, y: geometry.center.y + geometry.astrolabeRadius * 0.48), in: &context, geometry: geometry, color: OrlojDesignSystem.copper.opacity(0.92))
        context.stroke(projectedEclipticPath(geometry: geometry, stepDegrees: 3), with: .color(OrlojDesignSystem.highlightGold.opacity(0.62)), style: StrokeStyle(lineWidth: geometry.radius * 0.003, dash: [4, 5]))

        drawSmallLabel("DIAL SUN x \(state.dialSunProjection.x.formatted(.number.precision(.fractionLength(2)))) y \(state.dialSunProjection.y.formatted(.number.precision(.fractionLength(2))))", at: CGPoint(x: geometry.center.x, y: geometry.center.y - geometry.radius * 0.985), in: &context, geometry: geometry, color: OrlojDesignSystem.highlightGold.opacity(0.82))
        drawSmallLabel("MOON phase \(state.moonPhaseAngleLabel)", at: CGPoint(x: geometry.center.x, y: geometry.center.y + geometry.radius * 0.985), in: &context, geometry: geometry, color: OrlojDesignSystem.ivoryText.opacity(0.82))
    }

    private func drawGuideReadingOverlay(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        guard showsGuideReadingOverlay else {
            return
        }

        drawGuideTargetHighlight(activeLayers: currentGuideLayers, in: &context, geometry: geometry)
        if dialFocus.showAnnotations, let activeGuideItem {
            drawGuideCallout(guideCallout(for: activeGuideItem, geometry: geometry), in: &context, geometry: geometry)
        }
    }

    private func drawGuideTargetHighlight(activeLayers layers: Set<OrlojGuideLayerID>, in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let highlight = OrlojDesignSystem.highlightGold
        if layers.containsAny(.romanTimeRing, .romanNumerals, .civilHourTicks) {
            context.stroke(circle(center: geometry.center, radius: geometry.romanRadius + geometry.radius * 0.048), with: .color(highlight.opacity(0.76)), lineWidth: geometry.radius * 0.006)
            context.stroke(circle(center: geometry.center, radius: geometry.romanRadius - geometry.radius * 0.06), with: .color(highlight.opacity(0.42)), lineWidth: geometry.radius * 0.004)
            drawLine(
                from: geometry.polarPoint(radius: geometry.romanRadius - geometry.radius * 0.08, degrees: state.civilAngleDegrees),
                to: geometry.polarPoint(radius: geometry.romanRadius + geometry.radius * 0.07, degrees: state.civilAngleDegrees),
                in: &context,
                color: highlight.opacity(0.92),
                lineWidth: geometry.radius * 0.008
            )
        }

        if state.daylightWindow.kind == .normal, layers.containsAny(.oldCzechRing, .outer24Numerals, .sunsetAlignmentMarker) {
            context.stroke(circle(center: geometry.center, radius: geometry.oldCzechOuterRadius), with: .color(highlight.opacity(0.9)), lineWidth: geometry.radius * 0.008)
            context.stroke(circle(center: geometry.center, radius: geometry.oldCzechInnerRadius), with: .color(highlight.opacity(0.58)), lineWidth: geometry.radius * 0.006)
            context.stroke(circle(center: geometry.center, radius: geometry.oldCzechLabelRadius), with: .color(highlight.opacity(0.2)), style: StrokeStyle(lineWidth: geometry.radius * 0.022, lineCap: .round, lineJoin: .round))
            drawLine(
                from: geometry.polarPoint(radius: geometry.oldCzechOuterRadius, degrees: state.sunsetAngleDegrees),
                to: geometry.polarPoint(radius: geometry.oldCzechInnerRadius - geometry.radius * 0.035, degrees: state.sunsetAngleDegrees),
                in: &context,
                color: highlight.opacity(0.96),
                lineWidth: geometry.radius * 0.01
            )
        }

        if layers.containsAny(.sunMarker, .sunHand, .solarLongitudePoint, .eclipticPosition) {
            let sunPoint = geometry.screenPoint(state.dialSunProjection)
            let solarLongitudePoint = projectedEclipticPoint(longitude: state.dialSolarLongitudeDegrees, geometry: geometry)
            let handEnd = geometry.polarPoint(radius: geometry.oldCzechInnerRadius, degrees: goldenHandAngle.degrees)
            drawLine(from: geometry.center, to: handEnd, in: &context, color: OrlojDesignSystem.shadowBrown.opacity(0.76), lineWidth: geometry.radius * 0.014)
            drawLine(from: geometry.center, to: handEnd, in: &context, color: highlight.opacity(0.74), lineWidth: geometry.radius * 0.007)
            drawLine(from: geometry.center, to: handEnd, in: &context, color: OrlojDesignSystem.ivoryText.opacity(0.36), lineWidth: geometry.radius * 0.002)
            context.stroke(circle(center: sunPoint, radius: geometry.radius * 0.071), with: .color(highlight.opacity(0.82)), lineWidth: geometry.radius * 0.006)
            context.stroke(circle(center: sunPoint, radius: geometry.radius * 0.048), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.76)), lineWidth: geometry.radius * 0.002)
            context.fill(circle(center: solarLongitudePoint, radius: geometry.radius * 0.012), with: .color(highlight.opacity(0.62)))
            context.stroke(circle(center: solarLongitudePoint, radius: geometry.radius * 0.024), with: .color(highlight.opacity(0.5)), lineWidth: geometry.radius * 0.003)
            let horizon = OrlojProjection.constantAltitudeBoundary(latitudeDegrees: state.location.coordinates.latitude, altitudeDegrees: 0)
            context.stroke(
                boundaryStrokePath(horizon, geometry: geometry),
                with: .color(OrlojDesignSystem.ivoryText.opacity(0.32)),
                style: StrokeStyle(lineWidth: geometry.radius * 0.0045, lineCap: .round, lineJoin: .round)
            )
            if layers.containsAny(.solarLongitudePoint, .eclipticPosition) {
                context.stroke(projectedEclipticPath(geometry: geometry, stepDegrees: 3), with: .color(highlight.opacity(0.38)), style: StrokeStyle(lineWidth: geometry.radius * 0.006, dash: [5, 5]))
            }
        }

        if layers.containsAny(.moonMarker, .moonPhase, .lunarPosition) {
            let moonPoint = geometry.screenPoint(state.dialMoonProjection)
            drawLine(from: geometry.center, to: moonPoint, in: &context, color: OrlojDesignSystem.shadowBrown.opacity(0.72), lineWidth: geometry.radius * 0.009)
            drawLine(from: geometry.center, to: moonPoint, in: &context, color: OrlojDesignSystem.ivoryText.opacity(0.62), lineWidth: geometry.radius * 0.0045)
            context.stroke(circle(center: moonPoint, radius: geometry.radius * 0.072), with: .color(OrlojDesignSystem.ivoryText.opacity(0.76)), lineWidth: geometry.radius * 0.006)
            context.stroke(circle(center: moonPoint, radius: geometry.radius * 0.051), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.72)), lineWidth: geometry.radius * 0.0022)
        }

        if layers.containsAny(.zodiacRing, .zodiacGlyphs, .eclipticPath) {
            context.stroke(projectedEclipticPath(geometry: geometry, stepDegrees: 2), with: .color(highlight.opacity(0.82)), style: StrokeStyle(lineWidth: geometry.radius * 0.012, lineCap: .round, lineJoin: .round))
            context.stroke(projectedEclipticPath(geometry: geometry, stepDegrees: 2), with: .color(OrlojDesignSystem.ink.opacity(0.72)), style: StrokeStyle(lineWidth: geometry.radius * 0.004, lineCap: .round, lineJoin: .round))
        }

        if layers.containsAny(.horizonCurve, .ortusLabel, .occasusLabel) {
            let horizon = OrlojProjection.constantAltitudeBoundary(latitudeDegrees: state.location.coordinates.latitude, altitudeDegrees: 0)
            context.stroke(boundaryStrokePath(horizon, geometry: geometry), with: .color(highlight.opacity(0.9)), style: StrokeStyle(lineWidth: geometry.radius * 0.008, lineCap: .round, lineJoin: .round))
            drawSmallLabel("ORTVS", at: CGPoint(x: geometry.center.x - geometry.astrolabeRadius * 0.78, y: geometry.center.y - geometry.astrolabeRadius * 0.1), in: &context, geometry: geometry, color: highlight.opacity(0.96))
            drawSmallLabel("OCCASVS", at: CGPoint(x: geometry.center.x + geometry.astrolabeRadius * 0.78, y: geometry.center.y - geometry.astrolabeRadius * 0.1), in: &context, geometry: geometry, color: highlight.opacity(0.96))
        }

        if layers.containsAny(.twilightBand, .auroraLabel, .crepusculumLabel, .nightBoundary) {
            let horizon = OrlojProjection.constantAltitudeBoundary(latitudeDegrees: state.location.coordinates.latitude, altitudeDegrees: 0)
            let night = OrlojProjection.constantAltitudeBoundary(latitudeDegrees: state.location.coordinates.latitude, altitudeDegrees: -18)
            context.stroke(boundaryStrokePath(horizon, geometry: geometry), with: .color(OrlojDesignSystem.twilightOchre.opacity(0.9)), style: StrokeStyle(lineWidth: geometry.radius * 0.006, dash: [7, 4]))
            context.stroke(boundaryStrokePath(night, geometry: geometry), with: .color(highlight.opacity(0.82)), style: StrokeStyle(lineWidth: geometry.radius * 0.007, dash: [6, 4]))
            drawSmallLabel("AVRORA", at: CGPoint(x: geometry.center.x - geometry.astrolabeRadius * 0.62, y: geometry.center.y + geometry.astrolabeRadius * 0.1), in: &context, geometry: geometry, color: highlight.opacity(0.9))
            drawSmallLabel("CREPVSCVLVM", at: CGPoint(x: geometry.center.x + geometry.astrolabeRadius * 0.58, y: geometry.center.y + geometry.astrolabeRadius * 0.1), in: &context, geometry: geometry, color: highlight.opacity(0.9))
        }

        if layers.containsAny(.unequalHourLines, .daylightHourCurves) {
            let horizon = OrlojProjection.constantAltitudeBoundary(latitudeDegrees: state.location.coordinates.latitude, altitudeDegrees: 0)
            var hourContext = context
            hourContext.clip(to: circle(center: geometry.center, radius: geometry.coloredPlateRadius))
            hourContext.clip(
                to: dayRegionPath(horizon, plateRect: geometry.coloredPlateRect, geometry: geometry),
                style: FillStyle(eoFill: true)
            )

            for samples in state.unequalHourBoundaries {
                let path = projectedHourArcPath(samples: samples, geometry: geometry)
                hourContext.stroke(
                    path,
                    with: .color(OrlojDesignSystem.shadowBrown.opacity(0.34)),
                    style: StrokeStyle(lineWidth: geometry.radius * 0.0026, lineCap: .round, lineJoin: .round)
                )
                hourContext.stroke(
                    path,
                    with: .color(highlight.opacity(0.46)),
                    style: StrokeStyle(lineWidth: geometry.radius * 0.0016, lineCap: .round, lineJoin: .round)
                )
            }
        }

        if layers.containsAny(.ariesStar, .siderealReference, .zodiacZeroPoint) {
            let ariesPoint = ariesStarPoint(geometry: geometry)
            context.stroke(projectedEclipticPath(geometry: geometry, stepDegrees: 3), with: .color(highlight.opacity(0.44)), style: StrokeStyle(lineWidth: geometry.radius * 0.005, dash: [5, 4]))
            context.fill(starPath(center: ariesPoint, outerRadius: geometry.radius * 0.038, innerRadius: geometry.radius * 0.014), with: .color(highlight.opacity(0.96)))
            context.stroke(circle(center: ariesPoint, radius: geometry.radius * 0.062), with: .color(highlight.opacity(0.72)), lineWidth: geometry.radius * 0.005)
        }

        if layers.containsAny(.tropicCancer, .tropicCapricorn) {
            let obliquity = OrlojCalculator.degreesToRadians(state.solar.obliquityDegrees)
            let cancer = geometry.screenLength(tan(.pi / 4 + obliquity / 2))
            let capricorn = geometry.screenLength(tan(.pi / 4 - obliquity / 2))
            context.stroke(circle(center: geometry.center, radius: cancer), with: .color(highlight.opacity(0.82)), lineWidth: geometry.radius * 0.006)
            context.stroke(circle(center: geometry.center, radius: capricorn), with: .color(highlight.opacity(0.72)), lineWidth: geometry.radius * 0.006)
            context.stroke(projectedEclipticPath(geometry: geometry, stepDegrees: 3), with: .color(highlight.opacity(0.38)), style: StrokeStyle(lineWidth: geometry.radius * 0.005, dash: [5, 5]))
            context.stroke(circle(center: geometry.screenPoint(state.dialSunProjection), radius: geometry.radius * 0.072), with: .color(highlight.opacity(0.85)), lineWidth: geometry.radius * 0.006)
        }
    }

    private func guideCallout(for item: OrlojGuideItem, geometry: OrlojDialGeometry) -> OrlojGuideCallout {
        OrlojGuideCallout(
            title: item.title,
            value: OrlojGuideCatalog.currentValue(for: item, state: state) ?? "",
            detail: item.calloutLabel ?? item.subtitle ?? item.shortDescription,
            anchor: guideCalloutAnchor(for: item, geometry: geometry)
        )
    }

    private func guideCalloutAnchor(for item: OrlojGuideItem, geometry: OrlojDialGeometry) -> CGPoint {
        switch item.id {
        case .romanTime:
            return geometry.polarPoint(radius: geometry.romanRadius, degrees: state.civilAngleDegrees)
        case .oldCzechTime:
            return geometry.polarPoint(radius: geometry.oldCzechInnerRadius, degrees: state.sunsetAngleDegrees)
        case .sun:
            return geometry.screenPoint(state.dialSunProjection)
        case .moon:
            return geometry.screenPoint(state.dialMoonProjection)
        case .zodiacRing:
            return projectedEclipticPoint(longitude: state.dialSolarLongitudeDegrees, geometry: geometry)
        case .horizon:
            // Eastern equatorial horizon: altitude zero at every latitude.
            return geometry.screenPoint(OrlojProjectionPoint(x: -1, y: 0))
        case .twilight:
            return CGPoint(x: geometry.center.x + geometry.astrolabeRadius * 0.48, y: geometry.center.y + geometry.astrolabeRadius * 0.28)
        case .unequalHours:
            return unequalHourCalloutAnchor(geometry: geometry)
        case .siderealAries:
            return ariesStarPoint(geometry: geometry)
        case .tropics:
            return geometry.screenPoint(state.dialSunProjection)
        }
    }

    private func unequalHourCalloutAnchor(geometry: OrlojDialGeometry) -> CGPoint {
        guard let samples = state.unequalHourBoundaries.dropFirst(5).first, let sample = samples.dropFirst(samples.count / 2).first else {
            return geometry.screenPoint(state.dialSunProjection)
        }

        return geometry.screenPoint(sample)
    }

    private func drawGuideCallout(_ callout: OrlojGuideCallout, in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let rect = guideCalloutRect(anchor: callout.anchor, geometry: geometry)
        let boxPath = chamferedRect(rect, chamfer: min(rect.height * 0.18, geometry.radius * 0.025))
        let connectorEnd = guideConnectorEnd(for: rect, anchor: callout.anchor)

        var leader = Path()
        leader.move(to: callout.anchor)
        leader.addQuadCurve(
            to: connectorEnd,
            control: CGPoint(
                x: (callout.anchor.x + connectorEnd.x) / 2,
                y: min(callout.anchor.y, connectorEnd.y) - geometry.radius * 0.035
            )
        )
        context.stroke(
            leader,
            with: .color(OrlojDesignSystem.shadowBrown.opacity(0.5)),
            style: StrokeStyle(lineWidth: geometry.radius * 0.0052, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            leader,
            with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.5)),
            style: StrokeStyle(lineWidth: geometry.radius * 0.0021, lineCap: .round, lineJoin: .round)
        )
        context.stroke(circle(center: callout.anchor, radius: geometry.radius * 0.034), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.66)), lineWidth: geometry.radius * 0.004)
        context.stroke(circle(center: callout.anchor, radius: geometry.radius * 0.031), with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.52)), lineWidth: geometry.radius * 0.002)
        context.stroke(circle(center: callout.anchor, radius: geometry.radius * 0.019), with: .color(OrlojDesignSystem.ivoryText.opacity(0.16)), lineWidth: geometry.radius * 0.0015)
        context.fill(boxPath, with: .color(OrlojDesignSystem.shadowBrown.opacity(0.3)))
        context.fill(boxPath, with: .radialGradient(
            Gradient(colors: [
                OrlojDesignSystem.enamelBlueBlack.opacity(0.82),
                OrlojDesignSystem.enamelDark.opacity(0.9),
                OrlojDesignSystem.ink.opacity(0.92),
                OrlojDesignSystem.shadowBrown.opacity(0.88)
            ]),
            center: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.2),
            startRadius: rect.height * 0.12,
            endRadius: rect.width * 0.78
        ))
        context.stroke(boxPath, with: .color(OrlojDesignSystem.shadowBrown.opacity(0.82)), lineWidth: geometry.radius * 0.006)
        context.stroke(boxPath, with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.54)), lineWidth: geometry.radius * 0.0022)
        context.stroke(insetChamferedRect(rect, inset: geometry.radius * 0.007, chamfer: min(rect.height * 0.14, geometry.radius * 0.02)), with: .color(OrlojDesignSystem.highlightGold.opacity(0.14)), lineWidth: geometry.radius * 0.0012)

        drawText(callout.title.uppercased(), at: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.28), in: &context, size: geometry.radius * 0.023, weight: .black, design: .serif, color: OrlojDesignSystem.highlightGold.opacity(0.82), tracking: geometry.radius * 0.002, shadowColor: OrlojDesignSystem.shadowBrown.opacity(0.86))
        drawText(callout.value, at: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.53), in: &context, size: geometry.radius * 0.02, weight: .semibold, design: .serif, color: OrlojDesignSystem.ivoryText.opacity(0.82), shadowColor: OrlojDesignSystem.shadowBrown.opacity(0.8))
        drawText(callout.detail, at: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.76), in: &context, size: geometry.radius * 0.0165, weight: .medium, design: .serif, color: OrlojDesignSystem.textMuted.opacity(0.82), shadowColor: OrlojDesignSystem.shadowBrown.opacity(0.72))
    }

    private func guideCalloutRect(anchor: CGPoint, geometry: OrlojDialGeometry) -> CGRect {
        let width = min(geometry.radius * 0.58, geometry.size.width * 0.46)
        let height = geometry.radius * 0.155
        let horizontalDirection: CGFloat = anchor.x < geometry.center.x ? 1 : -1
        var center = CGPoint(
            x: anchor.x + horizontalDirection * geometry.radius * 0.32,
            y: anchor.y - geometry.radius * 0.14
        )
        let inset = geometry.radius * 0.04
        let leftSafeInset = max(inset, geometry.size.width * 0.18)
        let minX = width / 2 + leftSafeInset
        let maxX = geometry.size.width - width / 2 - inset
        if minX <= maxX {
            center.x = center.x.clamped(to: minX...maxX)
        } else {
            center.x = geometry.size.width / 2
        }
        let minY = height / 2 + inset
        let maxY = geometry.size.height - height / 2 - inset
        if minY <= maxY {
            center.y = center.y.clamped(to: minY...maxY)
        } else {
            center.y = geometry.size.height / 2
        }

        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    private func guideConnectorEnd(for rect: CGRect, anchor: CGPoint) -> CGPoint {
        let x = anchor.x < rect.midX ? rect.minX : rect.maxX
        let y = anchor.y.clamped(to: (rect.minY + rect.height * 0.28)...(rect.maxY - rect.height * 0.28))
        return CGPoint(x: x, y: y)
    }

    private func drawLatinLabels(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        let plateRadius = geometry.coloredPlateRadius
        let shadow = Color.clear
        drawReadablePlateInscription(
            "AVRORA",
            degrees: 236,
            radius: plateRadius * 0.56,
            rotationDegrees: -20,
            width: plateRadius * 0.22,
            in: &context,
            geometry: geometry,
            size: geometry.radius * 0.024,
            weight: .semibold,
            color: OrlojDesignSystem.ink.opacity(0.88),
            shadowColor: shadow,
            trackingScale: 0.018
        )
        drawReadablePlateInscription(
            "CREPVSCVLVM",
            degrees: 124,
            radius: plateRadius * 0.58,
            rotationDegrees: 20,
            width: plateRadius * 0.34,
            in: &context,
            geometry: geometry,
            size: geometry.radius * 0.0195,
            weight: .semibold,
            color: OrlojDesignSystem.ink.opacity(0.88),
            shadowColor: shadow,
            trackingScale: 0.01
        )
        drawReadablePlateInscription(
            "ORTVS",
            degrees: 288,
            radius: plateRadius * 0.69,
            rotationDegrees: -16,
            width: plateRadius * 0.2,
            in: &context,
            geometry: geometry,
            size: geometry.radius * 0.031,
            weight: .black,
            color: OrlojDesignSystem.ink.opacity(0.96),
            shadowColor: shadow,
            trackingScale: 0.014
        )
        drawReadablePlateInscription(
            "OCCASVS",
            degrees: 72,
            radius: plateRadius * 0.69,
            rotationDegrees: 16,
            width: plateRadius * 0.26,
            in: &context,
            geometry: geometry,
            size: geometry.radius * 0.03,
            weight: .black,
            color: OrlojDesignSystem.ink.opacity(0.96),
            shadowColor: shadow,
            trackingScale: 0.012
        )
        drawPlateInscription(
            "NOX",
            at: CGPoint(x: geometry.center.x, y: geometry.center.y + geometry.astrolabeRadius * 0.52),
            rotationDegrees: 0,
            width: plateRadius * 0.2,
            in: &context,
            geometry: geometry,
            size: geometry.radius * 0.037,
            weight: .black,
            color: OrlojDesignSystem.ivoryText.opacity(0.36),
            shadowColor: OrlojDesignSystem.ink.opacity(0.68),
            showRule: false,
            trackingScale: 0.09
        )
    }

    private func drawReadablePlateInscription(
        _ string: String,
        degrees: Double,
        radius: CGFloat,
        rotationDegrees: Double,
        width: CGFloat,
        in context: inout GraphicsContext,
        geometry: OrlojDialGeometry,
        size: CGFloat,
        weight: Font.Weight,
        color: Color,
        shadowColor: Color,
        trackingScale: CGFloat = 0.075
    ) {
        let location = polarPoint(center: geometry.center, radius: radius, degrees: degrees)
        drawPlateInscription(
            string,
            at: location,
            rotationDegrees: rotationDegrees,
            width: width,
            in: &context,
            geometry: geometry,
            size: size,
            weight: weight,
            color: color,
            shadowColor: shadowColor,
            trackingScale: trackingScale
        )
    }

    private func drawPlateInscription(
        _ string: String,
        at location: CGPoint,
        rotationDegrees: Double,
        width: CGFloat,
        in context: inout GraphicsContext,
        geometry: OrlojDialGeometry,
        size: CGFloat,
        weight: Font.Weight,
        color: Color,
        shadowColor: Color,
        showRule: Bool = false,
        trackingScale: CGFloat = 0.075
    ) {
        if showRule {
            var rotated = context
            rotated.translateBy(x: location.x, y: location.y)
            rotated.rotate(by: .degrees(rotationDegrees))

            let y = size * 0.78
            var engravedRule = Path()
            engravedRule.move(to: CGPoint(x: -width / 2, y: y))
            engravedRule.addCurve(
                to: CGPoint(x: width / 2, y: y),
                control1: CGPoint(x: -width * 0.18, y: y + size * 0.12),
                control2: CGPoint(x: width * 0.18, y: y - size * 0.08)
            )
            rotated.stroke(
                engravedRule,
                with: .color(OrlojDesignSystem.shadowBrown.opacity(0.34)),
                style: StrokeStyle(lineWidth: max(1, geometry.radius * 0.0034), lineCap: .round, lineJoin: .round)
            )
            rotated.stroke(
                engravedRule,
                with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.18)),
                style: StrokeStyle(lineWidth: max(0.7, geometry.radius * 0.0012), lineCap: .round, lineJoin: .round)
            )
        }

        drawText(
            string,
            at: location,
            in: &context,
            size: size,
            weight: weight,
            design: .serif,
            color: color,
            tracking: size * trackingScale,
            shadowColor: shadowColor,
            rotationDegrees: rotationDegrees
        )
    }

    private func projectedEclipticPath(geometry: OrlojDialGeometry, stepDegrees: Double) -> Path {
        var path = Path()
        var didMove = false
        for longitude in stride(from: 0.0, through: 360.0, by: stepDegrees) {
            let point = projectedEclipticPoint(longitude: longitude, geometry: geometry)
            if didMove {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                didMove = true
            }
        }
        path.closeSubpath()
        return path
    }

    private func projectedEclipticPoint(longitude: Double, geometry: OrlojDialGeometry) -> CGPoint {
        geometry.screenPoint(
            OrlojProjection.projectEcliptic(
                longitudeDegrees: longitude,
                latitudeDegrees: 0,
                obliquityDegrees: state.solar.obliquityDegrees,
                localSiderealTimeDegrees: state.solar.localSiderealTimeDegrees
            )
        )
    }

    private func eclipticTangentDegrees(longitude: Double, geometry: OrlojDialGeometry) -> Double {
        let before = projectedEclipticPoint(longitude: longitude - 1.2, geometry: geometry)
        let after = projectedEclipticPoint(longitude: longitude + 1.2, geometry: geometry)
        return OrlojCalculator.radiansToDegrees(atan2(after.y - before.y, after.x - before.x))
    }

    private func boundaryLowerRegionPath(_ boundary: OrlojProjectionBoundary, geometry: OrlojDialGeometry) -> Path {
        OrlojAltitudeRegionPath.make(
            boundary: boundary,
            belowBoundary: true,
            plateRect: geometry.coloredPlateRect,
            projectionScale: geometry.projectionScale
        )
    }

    private func dayRegionPath(_ horizon: OrlojProjectionBoundary, plateRect: CGRect, geometry: OrlojDialGeometry) -> Path {
        OrlojAltitudeRegionPath.make(
            boundary: horizon,
            belowBoundary: false,
            plateRect: plateRect,
            projectionScale: geometry.projectionScale
        )
    }

    private func boundaryStrokePath(_ boundary: OrlojProjectionBoundary, geometry: OrlojDialGeometry) -> Path {
        switch boundary {
        case .circle(let circle):
            return self.circle(center: geometry.screenPoint(circle.center), radius: geometry.screenLength(circle.radius))
        case .lineY(let projectedY):
            let screenY = geometry.screenY(forProjectedY: projectedY)
            var path = Path()
            path.move(to: CGPoint(x: geometry.coloredPlateRect.minX, y: screenY))
            path.addLine(to: CGPoint(x: geometry.coloredPlateRect.maxX, y: screenY))
            return path
        }
    }

    private func drawPaintedPatina(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        OrlojDialMaterials.paintedSurface(in: &context, bounds: geometry.coloredPlateRect)
    }

    private func drawOuterBeadedFrame(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        for index in 0..<72 {
            let degrees = Double(index) * 5
            let isHour = index.isMultiple(of: 3)
            let radius = geometry.radius * (isHour ? 0.974 : 0.966)
            let point = geometry.polarPoint(radius: radius, degrees: degrees)
            let beadRadius = geometry.radius * (isHour ? 0.0062 : 0.0036)
            context.fill(circle(center: point, radius: beadRadius), with: .radialGradient(
                Gradient(colors: [
                    OrlojDesignSystem.highlightGold.opacity(isHour ? 0.42 : 0.28),
                    OrlojDesignSystem.agedGoldEdge.opacity(isHour ? 0.32 : 0.2),
                    OrlojDesignSystem.oxidizedBrass.opacity(0.36)
                ]),
                center: CGPoint(x: point.x - beadRadius * 0.45, y: point.y - beadRadius * 0.45),
                startRadius: beadRadius * 0.1,
                endRadius: beadRadius
            ))
        }
    }

    private func drawAgedMetalWear(in context: inout GraphicsContext, geometry: OrlojDialGeometry) {
        for index in 0..<54 {
            let degrees = Double((index * 47 + 11) % 360)
            let radius = geometry.radius * CGFloat(0.88 + Double((index * 19) % 11) / 100.0)
            let point = geometry.polarPoint(radius: radius, degrees: degrees)
            let width = geometry.radius * CGFloat(0.004 + Double(index % 5) * 0.0012)
            context.fill(circle(center: point, radius: width), with: .color(OrlojDesignSystem.wornGilding.opacity(0.035)))
        }
    }

    private func drawZodiacGlyph(
        _ sign: ZodiacSign,
        at point: CGPoint,
        longitude: Double,
        isCurrent: Bool,
        in context: inout GraphicsContext,
        geometry: OrlojDialGeometry,
        alpha: Double
    ) {
        let angle = eclipticTangentDegrees(longitude: longitude, geometry: geometry)
        let size = geometry.radius * 0.106
        var glyphContext = context
        glyphContext.translateBy(x: point.x, y: point.y)
        glyphContext.rotate(by: .degrees(angle))

        glyphContext.opacity *= alpha
        let goldImage = glyphContext.resolve(Image("refined_" + sign.assetName).renderingMode(.original))
        glyphContext.draw(goldImage, in: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))

        if isCurrent && dialFocus.focus == .zodiac {
            context.stroke(
                circle(center: point, radius: size * 0.62),
                with: .color(OrlojDesignSystem.highlightGold.opacity(0.36 * alpha)),
                lineWidth: geometry.radius * 0.0025
            )
        }
    }

    private func drawEclipticSeparator(
        longitude: Double,
        in context: inout GraphicsContext,
        geometry: OrlojDialGeometry,
        alpha: Double
    ) {
        let point = zodiacBandPoint(longitude: longitude, geometry: geometry)
        let before = projectedEclipticPoint(longitude: longitude - 1, geometry: geometry)
        let after = projectedEclipticPoint(longitude: longitude + 1, geometry: geometry)
        let dx = after.x - before.x
        let dy = after.y - before.y
        let length = max(1, hypot(dx, dy))
        let normal = CGPoint(x: -dy / length, y: dx / length)
        let half = geometry.radius * 0.055
        drawLine(
            from: CGPoint(x: point.x - normal.x * half * 1.08, y: point.y - normal.y * half * 1.08),
            to: CGPoint(x: point.x + normal.x * half * 1.08, y: point.y + normal.y * half * 1.08),
            in: &context,
            color: OrlojDesignSystem.shadowBrown.opacity(0.74 * alpha),
            lineWidth: geometry.radius * 0.0044
        )
        drawLine(
            from: CGPoint(x: point.x - normal.x * half, y: point.y - normal.y * half),
            to: CGPoint(x: point.x + normal.x * half, y: point.y + normal.y * half),
            in: &context,
            color: OrlojDesignSystem.gold.opacity(0.85 * alpha),
            lineWidth: geometry.radius * 0.0015
        )
        context.fill(circle(center: point, radius: geometry.radius * 0.0042), with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.24 * alpha)))
    }

    private func drawSunIcon(at center: CGPoint, radius: CGFloat, in context: inout GraphicsContext, alpha: Double) {
        OrlojSolarOrnaments.sun(at: center, radius: radius, in: &context, alpha: alpha)
    }

    private func drawMoonIcon(at center: CGPoint, radius: CGFloat, in context: inout GraphicsContext, alpha: Double, supportAngleRadians: Double) {
        OrlojMoonRenderer.draw(center: center, radius: radius, in: &context, alpha: alpha,
            phaseAngleDegrees: state.lunar.phaseAngleDegrees, illumination: state.lunar.illumination, supportAngleRadians: supportAngleRadians)
    }

    private func drawSymbolicWorldLines(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let lineColor = OrlojDesignSystem.agedGoldEdge.opacity(0.16)
        let shadowColor = OrlojDesignSystem.shadowBrown.opacity(0.12)
        context.stroke(circle(center: center, radius: radius * 0.66), with: .color(shadowColor), lineWidth: radius * 0.022)
        context.stroke(circle(center: center, radius: radius * 0.66), with: .color(lineColor), lineWidth: radius * 0.01)

        var vertical = Path()
        vertical.move(to: CGPoint(x: center.x, y: center.y - radius * 0.62))
        vertical.addLine(to: CGPoint(x: center.x, y: center.y + radius * 0.62))
        context.stroke(vertical, with: .color(shadowColor), lineWidth: radius * 0.018)
        context.stroke(vertical, with: .color(lineColor), lineWidth: radius * 0.008)

        var river = Path()
        river.move(to: CGPoint(x: center.x - radius * 0.58, y: center.y - radius * 0.04))
        river.addCurve(
            to: CGPoint(x: center.x + radius * 0.58, y: center.y + radius * 0.05),
            control1: CGPoint(x: center.x - radius * 0.24, y: center.y - radius * 0.18),
            control2: CGPoint(x: center.x + radius * 0.24, y: center.y + radius * 0.18)
        )
        context.stroke(river, with: .color(shadowColor), lineWidth: radius * 0.02)
        context.stroke(river, with: .color(OrlojDesignSystem.verdigris.opacity(0.12)), lineWidth: radius * 0.01)

        for index in 0..<5 {
            let degrees = Double(index * 67 + 18)
            let point = polarPoint(center: center, radius: radius * CGFloat(0.22 + Double(index % 3) * 0.14), degrees: degrees)
            context.fill(circle(center: point, radius: radius * CGFloat(0.022 + Double(index % 2) * 0.008)), with: .color(OrlojDesignSystem.verdigris.opacity(0.07)))
        }
    }

    private func rotatedChamferedPlaque(center: CGPoint, width: CGFloat, height: CGFloat, chamfer: CGFloat, degrees: Double) -> Path {
        let cut = min(chamfer, min(width, height) * 0.42)
        let minX = -width / 2
        let maxX = width / 2
        let minY = -height / 2
        let maxY = height / 2
        var path = Path()
        path.move(to: CGPoint(x: minX + cut, y: minY))
        path.addLine(to: CGPoint(x: maxX - cut, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: 0))
        path.addLine(to: CGPoint(x: maxX - cut, y: maxY))
        path.addLine(to: CGPoint(x: minX + cut, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: 0))
        path.closeSubpath()

        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: CGFloat(OrlojCalculator.degreesToRadians(degrees)))
        return path.applying(transform)
    }

    private func chamferedRect(_ rect: CGRect, chamfer: CGFloat) -> Path {
        let cut = min(chamfer, min(rect.width, rect.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.closeSubpath()
        return path
    }

    private func insetChamferedRect(_ rect: CGRect, inset: CGFloat, chamfer: CGFloat) -> Path {
        let insetRect = rect.insetBy(dx: min(inset, rect.width * 0.2), dy: min(inset, rect.height * 0.2))
        return chamferedRect(insetRect, chamfer: chamfer)
    }

    private func drawSmallLabel(
        _ string: String,
        at location: CGPoint,
        in context: inout GraphicsContext,
        geometry: OrlojDialGeometry,
        color: Color
    ) {
        let fontSize = max(7, min(13, geometry.radius * (compact ? 0.022 : 0.026)))
        drawText(
            string,
            at: location,
            in: &context,
            size: fontSize,
            weight: .semibold,
            design: .serif,
            color: color,
            tracking: fontSize * 0.06,
            shadowColor: OrlojDesignSystem.ink.opacity(0.55)
        )
    }

    private func drawText(
        _ string: String,
        at location: CGPoint,
        in context: inout GraphicsContext,
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design,
        color: Color,
        tracking: CGFloat = 0,
        shadowColor: Color? = nil,
        rotationDegrees: Double = 0
    ) {
        if abs(rotationDegrees) > 0.001 {
            var rotated = context
            rotated.translateBy(x: location.x, y: location.y)
            rotated.rotate(by: .degrees(rotationDegrees))
            if let shadowColor {
                let shadow = rotated.resolve(
                    Text(string)
                        .font(.system(size: max(6, size), weight: weight, design: design))
                        .tracking(tracking)
                        .foregroundStyle(shadowColor)
                )
                rotated.draw(shadow, at: CGPoint(x: max(1, size * 0.055), y: max(1, size * 0.055)), anchor: .center)
            }
            let text = rotated.resolve(
                Text(string)
                    .font(.system(size: max(6, size), weight: weight, design: design))
                    .tracking(tracking)
                    .foregroundStyle(color)
            )
            rotated.draw(text, at: .zero, anchor: .center)
            return
        }

        if let shadowColor {
            let shadow = context.resolve(
                Text(string)
                    .font(.system(size: max(6, size), weight: weight, design: design))
                    .tracking(tracking)
                    .foregroundStyle(shadowColor)
            )
            context.draw(shadow, at: CGPoint(x: location.x + max(1, size * 0.055), y: location.y + max(1, size * 0.055)), anchor: .center)
        }
        let text = context.resolve(
            Text(string)
                .font(.system(size: max(6, size), weight: weight, design: design))
                .tracking(tracking)
                .foregroundStyle(color)
        )
        context.draw(text, at: location, anchor: .center)
    }

    private func drawLine(
        from start: CGPoint,
        to end: CGPoint,
        in context: inout GraphicsContext,
        color: Color,
        lineWidth: CGFloat
    ) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), lineWidth: max(1, lineWidth))
    }

    private func drawMetalAnnulus(
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        in context: inout GraphicsContext,
        base: Color,
        alpha: Double
    ) {
        let annulus = annulusPath(center: center, innerRadius: innerRadius, outerRadius: outerRadius)
        context.fill(annulus, with: .radialGradient(
            Gradient(colors: [
                OrlojDesignSystem.highlightGold.opacity(0.12 * alpha),
                OrlojDesignSystem.brassGold.opacity(0.18 * alpha),
                base.opacity(0.44 * alpha),
                OrlojDesignSystem.oxidizedBrass.opacity(0.62 * alpha),
                OrlojDesignSystem.shadowBrown.opacity(0.86 * alpha)
            ]),
            center: CGPoint(x: center.x - outerRadius * 0.18, y: center.y - outerRadius * 0.2),
            startRadius: innerRadius * 0.72,
            endRadius: outerRadius
        ), style: FillStyle(eoFill: true))
        context.stroke(circle(center: center, radius: outerRadius), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.78 * alpha)), lineWidth: max(1, outerRadius * 0.012))
        context.stroke(circle(center: center, radius: outerRadius - outerRadius * 0.006), with: .color(OrlojDesignSystem.highlightGold.opacity(0.22 * alpha)), lineWidth: max(1, outerRadius * 0.003))
        context.stroke(circle(center: center, radius: innerRadius), with: .color(OrlojDesignSystem.ink.opacity(0.68 * alpha)), lineWidth: max(1, outerRadius * 0.009))
        context.stroke(circle(center: center, radius: innerRadius + outerRadius * 0.004), with: .color(OrlojDesignSystem.agedGoldEdge.opacity(0.2 * alpha)), lineWidth: max(1, outerRadius * 0.003))
    }

    private func drawDarkEnamelAnnulus(
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        in context: inout GraphicsContext,
        alpha: Double
    ) {
        let annulus = annulusPath(center: center, innerRadius: innerRadius, outerRadius: outerRadius)
        context.fill(annulus, with: .radialGradient(
            Gradient(colors: [
                OrlojDesignSystem.enamelBlueBlack.opacity(0.72 * alpha),
                OrlojDesignSystem.ink.opacity(0.92 * alpha),
                OrlojDesignSystem.enamelDark.opacity(0.98 * alpha),
                OrlojDesignSystem.shadowBrown.opacity(0.9 * alpha)
            ]),
            center: CGPoint(x: center.x - outerRadius * 0.22, y: center.y - outerRadius * 0.18),
            startRadius: innerRadius * 0.9,
            endRadius: outerRadius
        ), style: FillStyle(eoFill: true))
        context.stroke(circle(center: center, radius: outerRadius), with: .color(OrlojDesignSystem.ink.opacity(0.7 * alpha)), lineWidth: max(1, outerRadius * 0.006))
        context.stroke(circle(center: center, radius: innerRadius), with: .color(OrlojDesignSystem.shadowBrown.opacity(0.68 * alpha)), lineWidth: max(1, outerRadius * 0.006))
    }

    private func annulusPath(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        ))
        path.addEllipse(in: CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
        return path
    }

    private func circle(center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }

    private func rayPath(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat, halfWidthDegrees: CGFloat, degrees: Double) -> Path {
        var path = Path()
        path.move(to: polarPoint(center: center, radius: outerRadius, degrees: degrees))
        path.addLine(to: polarPoint(center: center, radius: innerRadius, degrees: degrees - Double(halfWidthDegrees)))
        path.addLine(to: polarPoint(center: center, radius: innerRadius, degrees: degrees + Double(halfWidthDegrees)))
        path.closeSubpath()
        return path
    }

    private func polarPoint(center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let radians = CGFloat(OrlojCalculator.degreesToRadians(degrees - 90))
        return CGPoint(
            x: center.x + cos(radians) * radius,
            y: center.y + sin(radians) * radius
        )
    }

    private func starPath(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat) -> Path {
        var path = Path()
        for index in 0..<10 {
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(index) * 36 - 90
            let point = polarPoint(center: center, radius: radius, degrees: angle + 90)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func romanNumeral(for hour: Int) -> String {
        let value = hour % 12 == 0 ? 12 : hour % 12
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
        return numerals[value - 1]
    }

    private func layerAlpha(_ focus: OrlojLayerFocus, representedLayers: Set<OrlojGuideLayerID>) -> Double {
        if dialFocus.mode == .guide, !currentGuideLayers.isEmpty {
            return guideLayerAlpha(focus: focus, representedLayers: representedLayers, activeLayers: currentGuideLayers)
        }

        if dialFocus.focus == .all || dialFocus.focus == focus {
            return 1
        }
        return 0.18
    }

    private func sunAlpha() -> Double {
        if dialFocus.mode == .guide, !currentGuideLayers.isEmpty {
            let guideLayers = currentGuideLayers
            if guideLayers.containsAny(.sunMarker, .sunHand) {
                return 1
            }
            if guideLayers.containsAny(.zodiacRing, .zodiacGlyphs, .eclipticPath, .ariesStar, .zodiacZeroPoint, .solarLongitudePoint, .eclipticPosition) {
                return 0.56
            }

            return 0.18
        }

        return max(
            layerAlpha(.sun, representedLayers: [.sunMarker, .sunHand, .solarLongitudePoint, .eclipticPosition]),
            max(
                layerAlpha(.timeRings, representedLayers: [.romanTimeRing, .romanNumerals, .civilHourTicks]),
                layerAlpha(.zodiac, representedLayers: [.zodiacRing, .zodiacGlyphs, .eclipticPath])
            )
        )
    }

    private func guideLayerAlpha(
        focus: OrlojLayerFocus,
        representedLayers: Set<OrlojGuideLayerID>,
        activeLayers: Set<OrlojGuideLayerID>
    ) -> Double {
        guard !representedLayers.isEmpty else {
            return 0.16
        }

        if !representedLayers.isDisjoint(with: activeLayers) {
            return focus == .zodiac && activeLayers.containsAny(.sunMarker, .sunHand) ? 0.56 : 1
        }

        return 0.16
    }

    private var activeGuideItem: OrlojGuideItem? {
        OrlojGuideCatalog.item(for: dialFocus.activeGuideItemId)
    }

    private var currentGuideLayers: Set<OrlojGuideLayerID> {
        if !dialFocus.targetLayers.isEmpty {
            return dialFocus.targetLayers
        }

        return activeGuideItem?.targetLayerSet ?? []
    }

    private var showsDebugProjectionHelpers: Bool {
        dialFocus.mode == .debug
    }

    private var showsGuideTropicHighlight: Bool {
        dialFocus.mode == .guide && currentGuideLayers.containsAny(.tropicCancer, .tropicCapricorn)
    }

    private var showsGuideReadingOverlay: Bool {
        dialFocus.mode == .guide && !currentGuideLayers.isEmpty
    }
}

private struct OrlojGuideCallout {
    let title: String
    let value: String
    let detail: String
    let anchor: CGPoint
}

private extension Set where Element == OrlojGuideLayerID {
    func containsAny(_ layers: OrlojGuideLayerID...) -> Bool {
        layers.contains { contains($0) }
    }
}

// Circle exteriors use an even-odd fill and are clipped to the painted plate by
// the caller, just like the original northern day-region path.
enum OrlojAltitudeRegionPath {
    static func make(
        boundary: OrlojProjectionBoundary,
        belowBoundary: Bool,
        plateRect: CGRect,
        projectionScale: CGFloat
    ) -> Path {
        switch boundary {
        case .circle(let circle):
            let radius = CGFloat(circle.radius) * projectionScale
            let centerY = plateRect.midY - CGFloat(circle.centerY) * projectionScale
            var path = Path()
            if belowBoundary != circle.lowerAltitudeIsInside {
                path.addEllipse(in: plateRect)
            }
            path.addEllipse(in: CGRect(
                x: plateRect.midX - radius,
                y: centerY - radius,
                width: radius * 2,
                height: radius * 2
            ))
            return path
        case .lineY(let projectedY):
            let screenY = plateRect.midY - CGFloat(projectedY) * projectionScale
            return Path(CGRect(
                x: plateRect.minX,
                y: belowBoundary ? screenY : plateRect.minY,
                width: plateRect.width,
                height: belowBoundary ? plateRect.maxY - screenY : screenY - plateRect.minY
            ))
        }
    }
}

private struct OrlojDialGeometry {
    let size: CGSize
    let side: CGFloat
    let center: CGPoint
    let radius: CGFloat
    let projectionScale: CGFloat

    init(size: CGSize) {
        self.size = size
        side = min(size.width, size.height)
        center = CGPoint(x: size.width / 2, y: size.height / 2)
        radius = side * 0.48
        projectionScale = radius * 0.43
    }

    var astrolabeProjectionRadius: Double {
        1.72
    }

    var astrolabeRadius: CGFloat {
        screenLength(astrolabeProjectionRadius)
    }

    var astrolabeRect: CGRect {
        CGRect(
            x: center.x - astrolabeRadius,
            y: center.y - astrolabeRadius,
            width: astrolabeRadius * 2,
            height: astrolabeRadius * 2
        )
    }

    var coloredPlateRadius: CGFloat {
        oldCzechInnerRadius - radius * 0.004
    }

    var coloredPlateRect: CGRect {
        CGRect(
            x: center.x - coloredPlateRadius,
            y: center.y - coloredPlateRadius,
            width: coloredPlateRadius * 2,
            height: coloredPlateRadius * 2
        )
    }

    var romanRadius: CGFloat {
        radius * 0.781
    }

    var oldCzechInnerRadius: CGFloat {
        radius * 0.845
    }

    var oldCzechOuterRadius: CGFloat {
        radius * 0.985
    }

    var oldCzechLabelRadius: CGFloat {
        (oldCzechInnerRadius + oldCzechOuterRadius) / 2
    }

    func screenPoint(_ point: OrlojProjectionPoint) -> CGPoint {
        CGPoint(
            x: center.x + CGFloat(point.x) * projectionScale,
            y: center.y - CGFloat(point.y) * projectionScale
        )
    }

    func screenLength(_ projectedLength: Double) -> CGFloat {
        CGFloat(projectedLength) * projectionScale
    }

    func screenY(forProjectedY projectedY: Double) -> CGFloat {
        center.y - CGFloat(projectedY) * projectionScale
    }

    func screenRect(for circle: OrlojProjectionCircle) -> CGRect {
        let center = screenPoint(circle.center)
        let radius = screenLength(circle.radius)
        return CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    func polarPoint(radius: CGFloat, degrees: Double) -> CGPoint {
        let radians = CGFloat(OrlojCalculator.degreesToRadians(degrees - 90))
        return CGPoint(
            x: center.x + cos(radians) * radius,
            y: center.y + sin(radians) * radius
        )
    }

    func extendedRadialPoint(through point: CGPoint, radius: CGFloat) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let length = max(1, hypot(dx, dy))
        return CGPoint(
            x: center.x + dx / length * radius,
            y: center.y + dy / length * radius
        )
    }
}

struct ZodiacAssetIcon: View {
    let sign: ZodiacSign
    let size: CGFloat
    var opacity = 1.0
    var plated = false

    var body: some View {
        Image(sign.assetName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(OrlojDesignSystem.parchment.opacity(opacity))
            .frame(width: size, height: size)
            .padding(plated ? size * 0.28 : 0)
            .background {
                if plated {
                    Circle()
                        .fill(OrlojDesignSystem.ink.opacity(0.64 * opacity))
                }
            }
            .overlay {
                if plated {
                    Circle()
                        .stroke(OrlojDesignSystem.gold.opacity(0.34 * opacity), lineWidth: max(1, size * 0.06))
                }
            }
    }
}

#Preview {
    OrlojClockView(
        state: OrlojCalculator.state(for: Date(timeIntervalSince1970: 1_766_000_000), location: .prague),
        dialFocus: .manualFocus(.zodiac)
    )
    .padding()
    .background(OrlojDesignSystem.background)
}
