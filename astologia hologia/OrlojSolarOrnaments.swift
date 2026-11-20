import SwiftUI

/// Gilded sheet-metal forms informed by the detail photographs at
/// orloj.eu/cs/astro_cifernik.htm. These are scalable reconstructions, not tracings.
enum OrlojSolarOrnaments {
    static func sun(at center: CGPoint, radius: CGFloat, in context: inout GraphicsContext, alpha: Double) {
        var sun = context
        sun.opacity *= alpha
        sun.translateBy(x: center.x, y: center.y)
        sun.scaleBy(x: radius, y: radius)

        // Narrow, curling tongues of gilded sheet metal surround an unmarked boss.
        // No human face is identifiable in the reference, so none is invented here.
        for index in 0..<32 {
            let long = index.isMultiple(of: 2)
            let length: CGFloat = long ? 2.42 : 1.98
            let bend: CGFloat = long ? 0.13 : -0.18
            var ray = Path()
            ray.move(to: CGPoint(x: -0.115, y: -0.87))
            ray.addCurve(to: CGPoint(x: bend, y: -length),
                control1: CGPoint(x: -0.30, y: -1.47),
                control2: CGPoint(x: 0.24, y: -1.73))
            ray.addCurve(to: CGPoint(x: 0.12, y: -0.87),
                control1: CGPoint(x: 0.04, y: -1.86),
                control2: CGPoint(x: -0.08, y: -1.34))
            ray.closeSubpath()
            var rotated = sun
            rotated.rotate(by: .degrees(Double(index) * 11.25))
            var shadow = rotated
            shadow.translateBy(x: 0.055, y: 0.08)
            shadow.fill(ray, with: .color(.black.opacity(0.44)))
            rotated.fill(ray, with: OrlojDialMaterials.gilding(in: CGRect(x: -0.23, y: -length, width: 0.46, height: length)))
            rotated.stroke(ray, with: .color(OrlojDesignSystem.darkBrass.opacity(0.65)), lineWidth: 0.023)
            var crest = Path()
            crest.move(to: CGPoint(x: -0.018, y: -1.01))
            crest.addCurve(to: CGPoint(x: bend, y: -length * 0.93),
                control1: CGPoint(x: -0.14, y: -1.45),
                control2: CGPoint(x: 0.16, y: -1.68))
            rotated.stroke(crest, with: .color(Color(red: 1, green: 0.95, blue: 0.72).opacity(0.75)), lineWidth: 0.028)
        }

        let disk = Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2))
        var shadow = sun
        shadow.translateBy(x: 0.055, y: 0.08)
        shadow.fill(disk, with: .color(.black.opacity(0.55)))
        sun.fill(disk, with: .radialGradient(
            Gradient(stops: [
                .init(color: Color(red: 1, green: 0.97, blue: 0.78), location: 0),
                .init(color: Color(red: 0.98, green: 0.91, blue: 0.58), location: 0.24),
                .init(color: Color(red: 0.89, green: 0.74, blue: 0.34), location: 0.55),
                .init(color: Color(red: 0.64, green: 0.44, blue: 0.16), location: 0.85),
                .init(color: Color(red: 0.35, green: 0.23, blue: 0.08), location: 1)
            ]), center: CGPoint(x: -0.3, y: -0.36), startRadius: 0, endRadius: 1.48))
        OrlojDialMaterials.raisedRim(disk, in: &sun, bounds: disk.boundingRect, width: 0.065)
        OrlojDialMaterials.brushedGold(in: &sun, clip: disk, bounds: disk.boundingRect, strength: 0.4)
    }

    /// Local coordinates are in dial radii; the outstretched fingers read the scale.
    static func hand(in context: inout GraphicsContext, alpha: Double) {
        var metal = context
        metal.opacity *= alpha
        var hand = Path()
        hand.move(to: CGPoint(x: -0.015, y: -0.789))
        hand.addCurve(to: CGPoint(x: -0.026, y: -0.844), control1: CGPoint(x: -0.014, y: -0.81), control2: CGPoint(x: -0.018, y: -0.829))
        hand.addCurve(to: CGPoint(x: -0.049, y: -0.875), control1: CGPoint(x: -0.034, y: -0.85), control2: CGPoint(x: -0.051, y: -0.864))
        hand.addQuadCurve(to: CGPoint(x: -0.040, y: -0.880), control: CGPoint(x: -0.050, y: -0.884))
        hand.addLine(to: CGPoint(x: -0.020, y: -0.862))
        hand.addLine(to: CGPoint(x: -0.020, y: -0.936))
        hand.addQuadCurve(to: CGPoint(x: -0.011, y: -0.939), control: CGPoint(x: -0.018, y: -0.946))
        hand.addLine(to: CGPoint(x: -0.009, y: -0.901))
        hand.addLine(to: CGPoint(x: -0.006, y: -0.951))
        hand.addQuadCurve(to: CGPoint(x: 0.004, y: -0.951), control: CGPoint(x: -0.001, y: -0.962))
        hand.addLine(to: CGPoint(x: 0.007, y: -0.902))
        hand.addLine(to: CGPoint(x: 0.011, y: -0.944))
        hand.addQuadCurve(to: CGPoint(x: 0.021, y: -0.941), control: CGPoint(x: 0.018, y: -0.953))
        hand.addLine(to: CGPoint(x: 0.021, y: -0.896))
        hand.addLine(to: CGPoint(x: 0.026, y: -0.921))
        hand.addQuadCurve(to: CGPoint(x: 0.035, y: -0.918), control: CGPoint(x: 0.033, y: -0.929))
        hand.addLine(to: CGPoint(x: 0.033, y: -0.865))
        hand.addCurve(to: CGPoint(x: 0.015, y: -0.814), control1: CGPoint(x: 0.036, y: -0.846), control2: CGPoint(x: 0.017, y: -0.827))
        hand.addLine(to: CGPoint(x: 0.016, y: -0.789))
        hand.closeSubpath()

        var shadow = metal
        shadow.translateBy(x: 0.002, y: 0.004)
        shadow.fill(hand, with: .color(.black.opacity(0.56)))
        metal.fill(hand, with: .linearGradient(OrlojDialMaterials.gold,
            startPoint: CGPoint(x: -0.04, y: -0.88), endPoint: CGPoint(x: 0.036, y: -0.85)))
        metal.stroke(hand, with: .color(OrlojDesignSystem.darkBrass), lineWidth: 0.00125)
        OrlojDialMaterials.brushedGold(in: &metal, clip: hand, bounds: hand.boundingRect, strength: 0.65)

        // Shallow relief: palm, thumb fold and finger joints, rather than black outlines.
        var folds = Path()
        folds.move(to: CGPoint(x: -0.014, y: -0.856))
        folds.addQuadCurve(to: CGPoint(x: -0.006, y: -0.832), control: CGPoint(x: 0.003, y: -0.845))
        folds.move(to: CGPoint(x: -0.013, y: -0.875))
        folds.addQuadCurve(to: CGPoint(x: 0.025, y: -0.867), control: CGPoint(x: 0.006, y: -0.883))
        folds.move(to: CGPoint(x: -0.012, y: -0.850))
        folds.addQuadCurve(to: CGPoint(x: 0.022, y: -0.844), control: CGPoint(x: 0.005, y: -0.856))
        for (x, y) in [(-0.016, -0.916), (-0.001, -0.927), (0.016, -0.918), (0.029, -0.898)] {
            folds.move(to: CGPoint(x: x - 0.003, y: y))
            folds.addQuadCurve(to: CGPoint(x: x + 0.003, y: y), control: CGPoint(x: x, y: y + 0.0015))
        }
        for y in [-0.796, -0.803] {
            folds.move(to: CGPoint(x: -0.014, y: y))
            folds.addLine(to: CGPoint(x: 0.014, y: y))
        }
        metal.stroke(folds, with: .color(OrlojDesignSystem.darkBrass.opacity(0.58)),
            style: StrokeStyle(lineWidth: 0.0011, lineCap: .round))
        var highlights = metal
        highlights.translateBy(x: -0.0007, y: -0.0012)
        highlights.stroke(folds, with: .color(OrlojDesignSystem.highlightGold.opacity(0.7)), lineWidth: 0.00065)
    }
}
