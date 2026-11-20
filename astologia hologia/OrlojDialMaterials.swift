import SwiftUI

/// Sunlight on the dial, as if it hung where the Orloj does: on a wall facing
/// the equator (the Old Town Hall's south wall in Prague). Derived from the
/// Sun's altitude and azimuth at the dial's location and moment, so the
/// shadows lengthen, swing and soften with the hour and the season.
///
/// Screen vectors use x to the right and y downwards. `shadowShift` is the
/// shadow's displacement per unit of relief (both in dial radii) for a part
/// standing in front of the plate.
struct OrlojDialLighting: Equatable {
    /// Shadow displacement per unit of relief.
    var shadowShift: CGSize
    /// Opacity of a cast shadow on the painted plate.
    var shadowOpacity: Double
    /// 0 for the crisp shadows of direct sun, 1 for diffuse skylight.
    var shadowSoftness: Double
    /// 0 when the face is in shade or it is night, 1 in full direct sun.
    var sunlit: Double
    /// 0 at night, 1 in daylight (whether or not the sun reaches the face).
    var daylight: Double
    /// 0 for a high sun, towards 1 for low, golden light on the face.
    var warmth: Double
    /// Unit screen vector pointing towards the light.
    var lightDirection: CGSize

    /// The fixed upper-left light the dial used before lighting followed the Sun.
    static let studio = OrlojDialLighting(
        shadowShift: CGSize(width: 0.4, height: 0.9),
        shadowOpacity: 0.42,
        shadowSoftness: 0.3,
        sunlit: 0,
        daylight: 1,
        warmth: 0,
        lightDirection: CGSize(width: -0.406, height: -0.914)
    )

    init(
        shadowShift: CGSize,
        shadowOpacity: Double,
        shadowSoftness: Double,
        sunlit: Double,
        daylight: Double,
        warmth: Double,
        lightDirection: CGSize
    ) {
        self.shadowShift = shadowShift
        self.shadowOpacity = shadowOpacity
        self.shadowSoftness = shadowSoftness
        self.sunlit = sunlit
        self.daylight = daylight
        self.warmth = warmth
        self.lightDirection = lightDirection
    }

    /// - Parameters:
    ///   - sunAltitudeDegrees: Sun's altitude above the horizon.
    ///   - sunAzimuthDegrees: Sun's azimuth, from north through east.
    ///   - latitudeDegrees: Observer latitude; the wall faces the equator.
    init(sunAltitudeDegrees: Double, sunAzimuthDegrees: Double, latitudeDegrees: Double) {
        guard sunAltitudeDegrees.isFinite, sunAzimuthDegrees.isFinite else {
            self = .studio
            return
        }
        let wallAzimuth = latitudeDegrees >= 0 ? Double.pi : 0
        let altitude = sunAltitudeDegrees * .pi / 180
        let azimuth = sunAzimuthDegrees * .pi / 180
        let east = cos(altitude) * sin(azimuth)
        let north = cos(altitude) * cos(azimuth)
        let up = sin(altitude)
        // Components of the direction to the Sun along the wall's outward
        // normal and along the viewer's right as they face the wall.
        let normal = east * sin(wallAzimuth) + north * cos(wallAzimuth)
        let right = -east * cos(wallAzimuth) + north * sin(wallAzimuth)

        let aboveHorizon = Self.smoothstep(-0.5, 3, sunAltitudeDegrees)
        let facing = Self.smoothstep(0.02, 0.2, normal)
        let sunlit = aboveHorizon * facing

        // A part at relief h throws its shadow h·(-right, up)/normal across the
        // wall. Grazing light is clamped so shadows stay on the face.
        let safeNormal = max(normal, 0.08)
        var direct = CGSize(width: -right / safeNormal, height: up / safeNormal)
        let length = hypot(direct.width, direct.height)
        let maximumLength = 2.6
        if length > maximumLength {
            direct = CGSize(width: direct.width / length * maximumLength, height: direct.height / length * maximumLength)
        }
        // Without direct sun, the open sky above lights the face from above.
        let skylight = CGSize(width: 0, height: 0.35)

        let toSun = CGSize(width: right, height: -up)
        let toSunLength = hypot(toSun.width, toSun.height)
        let sunDirection = toSunLength > 0.05
            ? CGSize(width: toSun.width / toSunLength, height: toSun.height / toSunLength)
            : CGSize(width: 0, height: -1)
        let blended = CGSize(
            width: sunDirection.width * sunlit,
            height: sunDirection.height * sunlit - (1 - sunlit)
        )
        let blendedLength = max(0.0001, hypot(blended.width, blended.height))

        self.init(
            shadowShift: CGSize(
                width: skylight.width + (direct.width - skylight.width) * sunlit,
                height: skylight.height + (direct.height - skylight.height) * sunlit
            ),
            shadowOpacity: 0.24 + 0.32 * sunlit,
            shadowSoftness: 1 - sunlit,
            sunlit: sunlit,
            daylight: Self.smoothstep(-10, 1, sunAltitudeDegrees),
            warmth: sunlit * (1 - Self.smoothstep(3, 22, sunAltitudeDegrees)),
            lightDirection: CGSize(width: blended.width / blendedLength, height: blended.height / blendedLength)
        )
    }

    /// Shadow displacement, in dial radii, for a part `relief` radii in front of the plate.
    func shadowOffset(relief: CGFloat) -> CGSize {
        CGSize(width: shadowShift.width * relief, height: shadowShift.height * relief)
    }

    /// The same light described in a context rotated by `degrees`. Ratios
    /// such as `shadowShift` do not change with a uniform scale.
    func rotatedForLocalFrame(degrees: Double) -> OrlojDialLighting {
        var copy = self
        copy.shadowShift = Self.local(shadowShift, rotationDegrees: degrees, scale: 1)
        copy.lightDirection = Self.local(lightDirection, rotationDegrees: degrees, scale: 1)
        return copy
    }

    /// A screen-space vector expressed in a context rotated by `rotationDegrees`
    /// and scaled by `scale`, for drawing a shadow inside a local frame.
    static func local(_ vector: CGSize, rotationDegrees: Double, scale: CGFloat) -> CGSize {
        let angle = -rotationDegrees * .pi / 180
        let x = vector.width * CGFloat(cos(angle)) - vector.height * CGFloat(sin(angle))
        let y = vector.width * CGFloat(sin(angle)) + vector.height * CGFloat(cos(angle))
        return CGSize(width: x / scale, height: y / scale)
    }

    private static func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let t = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

/// Fixed, scale-independent surface detail. The grain is cached and never changes
/// with the clock tick, so the painted plate does not shimmer during time travel.
enum OrlojDialMaterials {
    static let gold = Gradient(stops: [
        .init(color: Color(red: 0.44, green: 0.31, blue: 0.13), location: 0),
        .init(color: Color(red: 0.81, green: 0.68, blue: 0.39), location: 0.18),
        .init(color: Color(red: 0.99, green: 0.93, blue: 0.70), location: 0.34),
        .init(color: Color(red: 0.73, green: 0.57, blue: 0.26), location: 0.49),
        .init(color: Color(red: 0.93, green: 0.80, blue: 0.48), location: 0.66),
        .init(color: Color(red: 0.63, green: 0.47, blue: 0.21), location: 0.86),
        .init(color: Color(red: 0.39, green: 0.27, blue: 0.12), location: 1)
    ])

    static func gilding(in bounds: CGRect) -> GraphicsContext.Shading {
        .linearGradient(gold,
            startPoint: CGPoint(x: bounds.minX, y: bounds.minY),
            endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY))
    }

    static func paintedSurface(in context: inout GraphicsContext, bounds: CGRect, strength: Double = 1) {
        var surface = context
        surface.clip(to: Path(ellipseIn: bounds))
        surface.fill(Path(bounds), with: .linearGradient(
            Gradient(stops: [
                .init(color: .white.opacity(0.15 * strength), location: 0),
                .init(color: .white.opacity(0.025 * strength), location: 0.40),
                .init(color: .clear, location: 0.58),
                .init(color: .black.opacity(0.13 * strength), location: 1)
            ]), startPoint: CGPoint(x: bounds.minX, y: bounds.minY),
            endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY)))
        surface.translateBy(x: bounds.minX, y: bounds.minY)
        surface.scaleBy(x: bounds.width, y: bounds.height)

        // Shallow variations in the old paint, with no cracks or invented damage.
        for index in 0..<28 {
            let x = unit(index * 4 + 9)
            let y = unit(index * 4 + 10)
            let radius = 0.035 + unit(index * 4 + 11) * 0.055
            let point = CGPoint(x: x, y: y)
            let area = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            surface.fill(Path(ellipseIn: area), with: .radialGradient(
                Gradient(colors: [(index.isMultiple(of: 2) ? Color.white : Color.black).opacity(0.025 * strength), .clear]),
                center: point, startRadius: 0, endRadius: radius))
        }
        surface.fill(darkGrain, with: .color(.black.opacity(0.10 * strength)))
        surface.fill(lightGrain, with: .color(.white.opacity(0.14 * strength)))
        surface.stroke(brushMarks, with: .color(.white.opacity(0.042 * strength)), lineWidth: 0.00028)
    }

    /// Gilding whose bright band faces the light.
    static func gilding(in bounds: CGRect, light: OrlojDialLighting) -> GraphicsContext.Shading {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let reach = hypot(bounds.width, bounds.height) / 2
        let direction = light.lightDirection
        return .linearGradient(gold,
            startPoint: CGPoint(x: center.x + direction.width * reach, y: center.y + direction.height * reach),
            endPoint: CGPoint(x: center.x - direction.width * reach, y: center.y - direction.height * reach))
    }

    static func raisedRim(_ path: Path, in context: inout GraphicsContext, bounds: CGRect, width: CGFloat, alpha: Double = 1,
                          light: OrlojDialLighting = .studio) {
        var metal = context
        metal.opacity *= alpha
        // The rim stands about two of its widths off the plate.
        let shift = light.shadowOffset(relief: width * 2)
        let shiftLength = hypot(shift.width, shift.height)
        let limit = width * 2.4
        let scale = shiftLength > limit ? limit / shiftLength : 1
        var shadow = metal
        shadow.translateBy(x: shift.width * scale, y: shift.height * scale)
        shadow.stroke(path, with: .color(.black.opacity(0.48 * light.shadowOpacity / OrlojDialLighting.studio.shadowOpacity)),
            lineWidth: width * (1.5 + light.shadowSoftness * 0.6))
        metal.stroke(path, with: gilding(in: bounds, light: light), lineWidth: width)
        var glint = metal
        glint.translateBy(x: light.lightDirection.width * width * 0.24, y: light.lightDirection.height * width * 0.24)
        glint.stroke(path, with: .color(Color(red: 1, green: 0.94, blue: 0.73).opacity(0.38 + 0.26 * light.sunlit)), lineWidth: width * 0.24)
    }

    static func brushedGold(in context: inout GraphicsContext, clip: Path, bounds: CGRect, strength: Double = 1) {
        var metal = context
        metal.clip(to: clip)
        metal.translateBy(x: bounds.minX, y: bounds.minY)
        metal.scaleBy(x: bounds.width, y: bounds.height)
        metal.fill(darkGrain, with: .color(.black.opacity(0.12 * strength)))
        metal.fill(lightGrain, with: .color(.white.opacity(0.18 * strength)))
        metal.stroke(brushMarks, with: .color(.white.opacity(0.13 * strength)), lineWidth: 0.0004)
    }

    private static func unit(_ seed: Int) -> CGFloat {
        var value = UInt64(seed + 1) &* 0x9E3779B97F4A7C15
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        value ^= value >> 31
        return CGFloat(value & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }

    private static let darkGrain = grain(offset: 0)
    private static let lightGrain = grain(offset: 14000)
    private static func grain(offset: Int) -> Path {
        var path = Path()
        for index in 0..<2200 {
            let x = unit(offset + index * 3)
            let y = unit(offset + index * 3 + 1)
            let radius = 0.0002 + unit(offset + index * 3 + 2) * 0.00045
            path.addEllipse(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
        }
        return path
    }

    private static let brushMarks: Path = {
        var path = Path()
        for index in 0..<430 {
            let x = unit(index * 5 + 27000)
            let y = unit(index * 5 + 27001)
            let length = 0.001 + unit(index * 5 + 27002) * 0.007
            path.move(to: CGPoint(x: x, y: y))
            path.addQuadCurve(to: CGPoint(x: x + length, y: y + 0.0004),
                              control: CGPoint(x: x + length * 0.5, y: y - 0.0003))
        }
        return path
    }()
}
