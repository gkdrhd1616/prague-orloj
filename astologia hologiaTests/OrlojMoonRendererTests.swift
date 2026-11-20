import Foundation
import SwiftUI
import Testing
@testable import astologia_hologia

struct OrlojMoonRendererTests {
    // Path.contains flattens curves in drawing-space points. A radius-one cubic
    // can be treated as a diamond, so compare geometry at high resolution while
    // retaining normalized coordinates in the independent sphere equations.
    private let containmentScale: CGFloat = 1_000

    @Test func quartersAreTrueHalfDisksAndNewAndFullAreCompleteExtremes() {
        let first = phasePath(90)
        let last = phasePath(270)
        let new = phasePath(0)
        let full = phasePath(180)
        // Test near the poles too: a narrow ellipse would fail these points.
        for y in [-0.9, -0.5, 0, 0.5, 0.9] {
            let right = samplePoint(x: 0.2, y: y)
            let left = samplePoint(x: -0.2, y: y)
            #expect(first.contains(right))
            #expect(!first.contains(left))
            #expect(last.contains(left))
            #expect(!last.contains(right))
            #expect(full.contains(right) && full.contains(left))
            #expect(!new.contains(right) && !new.contains(left))
        }
    }

    @Test func phaseMaskMatchesIndependentSphereIllumination() {
        var mismatches = 0
        var comparisons = 0
        for phase in stride(from: 15.0, through: 345.0, by: 15) {
            let path = phasePath(phase)
            let angle = phase * .pi / 180
            for row in -24...24 {
                for column in -24...24 {
                    let x = Double(column) / 25
                    let y = Double(row) / 25
                    let squaredRadius = x * x + y * y
                    guard squaredRadius < 0.98 else { continue }
                    let z = sqrt(1 - squaredRadius)
                    // Visible surface normal (x,y,z) dotted with Sun direction.
                    let lighting = x * sin(angle) - z * cos(angle)
                    // Exclude the numerical boundary of the cubic circle path.
                    guard abs(lighting) > 0.003 else { continue }
                    comparisons += 1
                    if path.contains(samplePoint(x: x, y: y)) != (lighting > 0) {
                        mismatches += 1
                    }
                }
            }
        }
        #expect(comparisons > 30_000)
        #expect(mismatches == 0)
    }

    @Test func illuminatedAreaMatchesTheModelFractionAndWaxingMirrorsWaning() {
        let gridSide = 160
        for phase in [30.0, 60, 90, 120, 150] {
            let fraction = (1 - cos(phase * .pi / 180)) / 2
            let waxing = phasePath(phase)
            let waning = phasePath(360 - phase)
            var illuminatedSamples = 0
            var diskSamples = 0
            var asymmetricSamples = 0
            for row in 0..<gridSide {
                for column in 0..<gridSide {
                    let x = (Double(column) + 0.5) / Double(gridSide) * 2 - 1
                    let y = (Double(row) + 0.5) / Double(gridSide) * 2 - 1
                    guard x * x + y * y < 1 else { continue }
                    diskSamples += 1
                    let lit = waxing.contains(samplePoint(x: x, y: y))
                    if lit { illuminatedSamples += 1 }
                    if lit != waning.contains(samplePoint(x: -x, y: y)) { asymmetricSamples += 1 }
                }
            }
            #expect(abs(Double(illuminatedSamples) / Double(diskSamples) - fraction) < 0.003)
            #expect(asymmetricSamples == 0)
        }
    }

    private func phasePath(_ degrees: Double) -> Path {
        OrlojMoonRenderer.illuminatedPath(
            center: .zero,
            radius: containmentScale,
            phaseAngleDegrees: degrees,
            illumination: (1 - cos(degrees * .pi / 180)) / 2
        )
    }

    private func samplePoint(x: Double, y: Double) -> CGPoint {
        CGPoint(x: CGFloat(x) * containmentScale, y: CGFloat(y) * containmentScale)
    }
}
