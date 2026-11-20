import SwiftUI

/// Slender applied-metal I/V/X forms, reconstructed from the 2019 dial photo.
/// Using outlines keeps their cap height and narrow spacing independent of the
/// platform's serif font. These proportions are optical, not surveyed dimensions.
enum OrlojRomanNumerals {
    static func draw(_ numeral: String, at center: CGPoint, height: CGFloat,
                     rotationDegrees: Double, in context: inout GraphicsContext, alpha: Double,
                     light: OrlojDialLighting = .studio) {
        guard let outline = outlines[numeral] else { return }
        var metal = context
        metal.opacity *= alpha
        metal.translateBy(x: center.x, y: center.y)
        metal.rotate(by: .degrees(rotationDegrees))
        metal.scaleBy(x: height, y: height)

        // A shallow offset describes gilded strips raised slightly off the plate.
        // Relief about 4% of the numeral's height, cast in the light's direction.
        let local = light.rotatedForLocalFrame(degrees: rotationDegrees)
        let contact = local.shadowOffset(relief: 0.042)
        var shadow = metal
        shadow.translateBy(x: contact.width, y: contact.height)
        shadow.fill(outline, with: .color(.black.opacity(0.47 * (0.6 + 0.7 * light.sunlit))))
        let toLight = local.lightDirection
        metal.fill(outline, with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.98, green: 0.91, blue: 0.68), location: 0),
                .init(color: Color(red: 0.85, green: 0.72, blue: 0.40), location: 0.45),
                .init(color: Color(red: 0.66, green: 0.51, blue: 0.24), location: 0.75),
                .init(color: Color(red: 0.93, green: 0.82, blue: 0.55), location: 1)
            ]), startPoint: CGPoint(x: outline.boundingRect.midX + toLight.width * 0.5, y: toLight.height * 0.5),
            endPoint: CGPoint(x: outline.boundingRect.midX - toLight.width * 0.5, y: -toLight.height * 0.5)))
        metal.stroke(outline, with: .color(OrlojDesignSystem.darkBrass.opacity(0.6)), lineWidth: 0.008)
    }

    private static let outlines: [String: Path] = {
        let values = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
        return Dictionary(uniqueKeysWithValues: values.map { ($0, outline(for: $0)) })
    }()

    private static func outline(for numeral: String) -> Path {
        let spacing: CGFloat = 0.045
        let widths: [Character: CGFloat] = ["I": 0.19, "V": 0.47, "X": 0.46]
        let total = numeral.reduce(CGFloat.zero) { $0 + (widths[$1] ?? 0) }
            + CGFloat(max(0, numeral.count - 1)) * spacing
        var x = -total / 2
        var result = Path()
        for letter in numeral {
            let width = widths[letter] ?? 0
            let glyph = letterPath(letter, width: width)
            result.addPath(glyph, transform: CGAffineTransform(translationX: x, y: -0.5))
            x += width + spacing
        }
        return result
    }

    private static func letterPath(_ letter: Character, width: CGFloat) -> Path {
        var path = Path()
        func polygon(_ points: [CGPoint]) {
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
        func serif(x: CGFloat, y: CGFloat, width: CGFloat) {
            path.addRect(CGRect(x: x, y: y, width: width, height: 0.022))
        }
        switch letter {
        case "I":
            polygon([CGPoint(x: 0, y: 0), CGPoint(x: width, y: 0),
                     CGPoint(x: width, y: 0.022), CGPoint(x: 0.13, y: 0.04),
                     CGPoint(x: 0.124, y: 0.955), CGPoint(x: width, y: 0.978),
                     CGPoint(x: width, y: 1), CGPoint(x: 0, y: 1),
                     CGPoint(x: 0, y: 0.978), CGPoint(x: 0.067, y: 0.955),
                     CGPoint(x: 0.061, y: 0.04), CGPoint(x: 0, y: 0.022)])
        case "V":
            polygon([CGPoint(x: 0.013, y: 0.013), CGPoint(x: 0.083, y: 0.013),
                     CGPoint(x: 0.252, y: 0.875), CGPoint(x: 0.215, y: 1)])
            polygon([CGPoint(x: width - 0.051, y: 0.013), CGPoint(x: width - 0.004, y: 0.013),
                     CGPoint(x: 0.239, y: 1), CGPoint(x: 0.215, y: 1)])
            serif(x: 0, y: 0, width: 0.155)
            serif(x: width - 0.13, y: 0, width: 0.13)
        case "X":
            polygon([CGPoint(x: 0.016, y: 0.011), CGPoint(x: 0.088, y: 0.011),
                     CGPoint(x: width - 0.014, y: 0.989), CGPoint(x: width - 0.086, y: 0.989)])
            polygon([CGPoint(x: width - 0.051, y: 0.011), CGPoint(x: width - 0.012, y: 0.011),
                     CGPoint(x: 0.051, y: 0.989), CGPoint(x: 0.012, y: 0.989)])
            for y: CGFloat in [0, 0.978] {
                serif(x: 0, y: y, width: 0.14)
                serif(x: width - 0.14, y: y, width: 0.14)
            }
        default:
            break
        }
        return path
    }
}
