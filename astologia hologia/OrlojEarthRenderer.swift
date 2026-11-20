import SwiftUI

/// Blue globe and curved gold graticule visible in the June 2019 reference.
/// The viewing tilt is an optical reconstruction, not a survey of the painting.
enum OrlojEarthRenderer {
    static func draw(center: CGPoint, radius: CGFloat, in context: inout GraphicsContext, light: OrlojDialLighting = .studio) {
        let disk = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2))
        context.fill(disk, with: .linearGradient(
            Gradient(colors: [Color(red: 0.12, green: 0.32, blue: 0.46),
                              Color(red: 0.32, green: 0.55, blue: 0.67),
                              Color(red: 0.63, green: 0.78, blue: 0.83)]),
            startPoint: CGPoint(x: center.x, y: center.y - radius),
            endPoint: CGPoint(x: center.x, y: center.y + radius)))
        var globe = context
        globe.clip(to: disk)
        OrlojDialMaterials.paintedSurface(in: &globe, bounds: disk.boundingRect, strength: 0.65)
        let transform = CGAffineTransform(translationX: center.x, y: center.y).scaledBy(x: radius, y: radius)
        let lines = graticule.applying(transform)
        globe.stroke(lines, with: .color(OrlojDesignSystem.darkBrass.opacity(0.7)), lineWidth: radius * 0.015)
        globe.stroke(lines, with: .color(Color(red: 0.91, green: 0.80, blue: 0.49).opacity(0.9)), lineWidth: radius * 0.007)
        OrlojDialMaterials.raisedRim(disk, in: &context, bounds: disk.boundingRect, width: radius * 0.016, light: light)
    }

    private static let graticule: Path = {
        var lines = Path()
        let tilt = 35.0 * .pi / 180
        func append(latitude: Double, longitude: Double, penDown: inout Bool) {
            let lat = latitude * .pi / 180
            let lon = longitude * .pi / 180
            let x = cos(lat) * sin(lon)
            let y = -(sin(lat) * cos(tilt) - cos(lat) * cos(lon) * sin(tilt))
            let depth = sin(lat) * sin(tilt) + cos(lat) * cos(lon) * cos(tilt)
            guard depth >= 0 else { penDown = false; return }
            let point = CGPoint(x: x, y: y)
            if penDown { lines.addLine(to: point) } else { lines.move(to: point) }
            penDown = true
        }
        for latitude in stride(from: -60.0, through: 75.0, by: 15) {
            var penDown = false
            for longitude in stride(from: -180.0, through: 180.0, by: 2) {
                append(latitude: latitude, longitude: longitude, penDown: &penDown)
            }
        }
        for longitude in stride(from: -180.0, to: 180.0, by: 20) {
            var penDown = false
            for latitude in stride(from: -90.0, through: 90.0, by: 2) {
                append(latitude: latitude, longitude: longitude, penDown: &penDown)
            }
        }
        return lines
    }()
}
