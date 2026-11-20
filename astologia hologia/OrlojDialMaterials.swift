import SwiftUI

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

    static func raisedRim(_ path: Path, in context: inout GraphicsContext, bounds: CGRect, width: CGFloat, alpha: Double = 1) {
        var metal = context
        metal.opacity *= alpha
        var shadow = metal
        shadow.translateBy(x: width * 0.45, y: width * 0.8)
        shadow.stroke(path, with: .color(.black.opacity(0.48)), lineWidth: width * 1.5)
        metal.stroke(path, with: gilding(in: bounds), lineWidth: width)
        var light = metal
        light.translateBy(x: -width * 0.14, y: -width * 0.2)
        light.stroke(path, with: .color(Color(red: 1, green: 0.94, blue: 0.73).opacity(0.54)), lineWidth: width * 0.24)
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
