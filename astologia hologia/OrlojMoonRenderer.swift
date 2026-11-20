import SwiftUI

/// The Orloj's rotating silver and black sphere. The model's phase angle is
/// elongation: 0° new, 90° first quarter, 180° full, 270° last quarter.
enum OrlojMoonRenderer {
    static func draw(
        center: CGPoint,
        radius: CGFloat,
        in context: inout GraphicsContext,
        alpha: Double,
        phaseAngleDegrees: Double,
        illumination: Double,
        supportAngleRadians: Double = 0,
        lightDirection: CGSize = CGSize(width: -0.57, height: -0.82)
    ) {
        // The reflections on the lacquer and silver sit on the side facing the light.
        let glint = CGPoint(x: center.x + lightDirection.width * radius * 0.48,
                            y: center.y + lightDirection.height * radius * 0.48)
        guard radius.isFinite, radius > 0, alpha.isFinite, alpha > 0 else { return }
        let sphere = Path(ellipseIn: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
        let silver = illuminatedPath(
            center: center,
            radius: radius,
            phaseAngleDegrees: phaseAngleDegrees,
            illumination: illumination
        )

        drawSupport(
            center: center, radius: radius,
            angleRadians: supportAngleRadians,
            in: &context, alpha: min(alpha, 1)
        )

        var moon = context
        moon.opacity *= min(alpha, 1)
        moon.clip(to: sphere)

        // Black lacquer has a restrained room reflection, not emitted light.
        moon.fill(sphere, with: .radialGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.16, green: 0.17, blue: 0.18), location: 0),
                .init(color: Color(red: 0.055, green: 0.063, blue: 0.071), location: 0.38),
                .init(color: Color(red: 0.014, green: 0.018, blue: 0.023), location: 0.78),
                .init(color: .black, location: 1)
            ]),
            center: glint,
            startRadius: 0,
            endRadius: radius * 1.55
        ))

        // A continuous sphere reflection is clipped by the actual silver
        // hemisphere. It does not change the terminator or painted phase area.
        moon.fill(silver, with: .radialGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.97, green: 0.97, blue: 0.93), location: 0),
                .init(color: Color(red: 0.80, green: 0.83, blue: 0.83), location: 0.24),
                .init(color: Color(red: 0.57, green: 0.62, blue: 0.65), location: 0.62),
                .init(color: Color(red: 0.27, green: 0.32, blue: 0.36), location: 0.88),
                .init(color: Color(red: 0.12, green: 0.15, blue: 0.18), location: 1)
            ]),
            center: glint,
            startRadius: 0,
            endRadius: radius * 1.65
        ))

        var reflection = moon
        reflection.clip(to: silver)
        let reflectedWindow = Path(ellipseIn: CGRect(
            x: center.x - radius * 0.63,
            y: center.y - radius * 0.60,
            width: radius * 0.82,
            height: radius * 0.22
        ))
        reflection.fill(reflectedWindow, with: .linearGradient(
            Gradient(colors: [.white.opacity(0.24), .white.opacity(0.04)]),
            startPoint: CGPoint(x: center.x, y: center.y - radius * 0.60),
            endPoint: CGPoint(x: center.x, y: center.y - radius * 0.38)
        ))

        // Only the sphere's narrow dark silhouette: no bezel or golden rings.
        moon.stroke(sphere, with: .color(.black.opacity(0.34)), lineWidth: radius * 0.045)
    }

    /// A narrow rear cradle and polar axle, as visible behind the physical
    /// silver-black globe. The globe is painted afterwards and hides the axle.
    /// Only this support rotates; neither the phase mask nor its lighting moves.
    private static func drawSupport(
        center: CGPoint,
        radius: CGFloat,
        angleRadians: Double,
        in context: inout GraphicsContext,
        alpha: Double
    ) {
        var support = context
        support.opacity *= alpha
        support.translateBy(x: center.x, y: center.y)
        support.rotate(by: .radians(angleRadians.isFinite ? angleRadians : 0))
        support.scaleBy(x: radius, y: radius)

        // Open on the left, with a small air gap around the sphere: a rear
        // bracket, rather than a complete decorative ring on its bright face.
        var cradle = Path()
        cradle.move(to: CGPoint(x: -0.57, y: -1.0))
        cradle.addCurve(to: CGPoint(x: 0, y: -1.15),
            control1: CGPoint(x: -0.40, y: -1.12), control2: CGPoint(x: -0.19, y: -1.15))
        cradle.addCurve(to: CGPoint(x: 1.15, y: 0),
            control1: CGPoint(x: 0.635, y: -1.15), control2: CGPoint(x: 1.15, y: -0.635))
        cradle.addCurve(to: CGPoint(x: 0, y: 1.15),
            control1: CGPoint(x: 1.15, y: 0.635), control2: CGPoint(x: 0.635, y: 1.15))
        cradle.addCurve(to: CGPoint(x: -0.82, y: 0.81),
            control1: CGPoint(x: -0.30, y: 1.15), control2: CGPoint(x: -0.62, y: 1.02))
        let fittedCradle = cradle.applying(CGAffineTransform(scaleX: 1.08 / 1.15, y: 1.08 / 1.15))
        support.stroke(fittedCradle, with: .color(Color(red: 0.025, green: 0.032, blue: 0.036)),
            style: StrokeStyle(lineWidth: 0.065, lineCap: .round, lineJoin: .round))
        support.stroke(fittedCradle, with: .color(Color(red: 0.27, green: 0.30, blue: 0.31).opacity(0.52)),
            style: StrokeStyle(lineWidth: 0.014, lineCap: .round))

        var axle = Path()
        axle.move(to: CGPoint(x: 0, y: -1.20))
        axle.addLine(to: CGPoint(x: 0, y: -0.98))
        axle.move(to: CGPoint(x: 0, y: 0.98))
        axle.addLine(to: CGPoint(x: 0, y: 1.20))
        support.stroke(axle, with: .color(Color(red: 0.035, green: 0.04, blue: 0.045)),
            style: StrokeStyle(lineWidth: 0.07, lineCap: .round))
        for y in [-1.08, 1.08] {
            support.fill(Path(CGRect(x: -0.065, y: y - 0.025, width: 0.13, height: 0.05)),
                with: .color(Color(red: 0.08, green: 0.09, blue: 0.10)))
        }
    }

    /// Orthographic projection of the silver hemisphere. At each height y,
    /// its terminator is x = ±(1 - 2I)√(r² - y²); the visible limb is circular.
    /// Cubic quarter-circle segments use the same standard circle approximation
    /// as vector drawing paths, with their x coordinates scaled for the ellipse.
    static func illuminatedPath(
        center: CGPoint,
        radius: CGFloat,
        phaseAngleDegrees: Double,
        illumination: Double
    ) -> Path {
        guard radius.isFinite, radius > 0 else { return Path() }
        let phase = normalizedPhase(phaseAngleDegrees)
        let fraction = illumination.isFinite
            ? min(max(illumination, 0), 1)
            : (1 - cos(phase * .pi / 180)) / 2
        guard fraction > 0 else { return Path() }
        if fraction >= 1 {
            return Path(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            ))
        }

        let side: CGFloat = phase < 180 ? 1 : -1
        let terminator = side * CGFloat(1 - 2 * fraction)
        let k: CGFloat = 0.5522847498307936
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: center.x + x * radius, y: center.y + y * radius)
        }

        var path = Path()
        path.move(to: point(0, -1))
        path.addCurve(to: point(side, 0), control1: point(side * k, -1), control2: point(side, -k))
        path.addCurve(to: point(0, 1), control1: point(side, k), control2: point(side * k, 1))
        path.addCurve(to: point(terminator, 0), control1: point(terminator * k, 1), control2: point(terminator, k))
        path.addCurve(to: point(0, -1), control1: point(terminator, -k), control2: point(terminator * k, -1))
        path.closeSubpath()
        return path
    }

    private static func normalizedPhase(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return 0 }
        let phase = degrees.truncatingRemainder(dividingBy: 360)
        return phase < 0 ? phase + 360 : phase
    }
}
