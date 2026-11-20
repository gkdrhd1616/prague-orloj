import Foundation
import Testing
@testable import astologia_hologia

/// The reading guide: complete, consistently worded and in order.
struct OrlojGuideContentTests {
    init() {
        OrlojLocalization.useSourceLanguageForTests()
    }

    @Test func everyTopicExplainsHowToReadIt() {
        for item in OrlojGuideCatalog.items {
            #expect(!item.shortDescription.isEmpty, "\(item.id)")
            #expect(item.longDescription?.isEmpty == false, "\(item.id)")
            #expect(!item.readingSteps.isEmpty, "\(item.id)")
            #expect(item.readingSteps.allSatisfy { !$0.isEmpty }, "\(item.id)")
        }
    }

    @Test func topicsAreListedSectionBySection() {
        // The list, its sections and Previous/Next all follow one order.
        let sectionOrder = OrlojGuideCatalog.items.map { OrlojGuideSection.allCases.firstIndex(of: $0.section)! }
        #expect(sectionOrder == sectionOrder.sorted())
        for section in OrlojGuideSection.allCases {
            #expect(!OrlojGuideCatalog.items(in: section).isEmpty, "\(section)")
        }
        #expect(Set(OrlojGuideCatalog.items.map(\.id)).count == OrlojGuideCatalog.items.count)
    }

    @Test func previousAndNextStepThroughTheGuide() throws {
        let first = try #require(OrlojGuideCatalog.items.first)
        let last = try #require(OrlojGuideCatalog.items.last)
        #expect(OrlojGuideCatalog.neighbour(of: first.id, offset: -1) == nil)
        #expect(OrlojGuideCatalog.neighbour(of: last.id, offset: 1) == nil)
        #expect(OrlojGuideCatalog.neighbour(of: first.id, offset: 1)?.id == OrlojGuideCatalog.items[1].id)
    }

    @Test func guideTextUsesOneLanguageAndTheDialsSpelling() {
        var texts = OrlojGuideCatalog.quickSteps + [
            OrlojGuideCatalog.overview, OrlojGuideCatalog.history,
            OrlojGuideCatalog.pragueModeNote, OrlojGuideCatalog.mySkyModeNote
        ]
        for item in OrlojGuideCatalog.items {
            texts += [item.title, item.shortDescription] + item.readingSteps
            texts += [item.subtitle, item.longDescription, item.pragueNote, item.calloutLabel].compactMap { $0 }
        }
        let hangul = Unicode.Scalar(UInt32(0xAC00))!...Unicode.Scalar(UInt32(0xD7A3))!
        for text in texts {
            #expect(!text.unicodeScalars.contains { hangul.contains($0) }, "\(text)")
            // The dial is lettered with V for U.
            #expect(!text.contains("ORTUS") && !text.contains("OCCASUS"), "\(text)")
        }
    }

    @Test func sourcesAreSecureLinks() {
        #expect(!OrlojGuideCatalog.sources.isEmpty)
        #expect(OrlojGuideCatalog.sources.allSatisfy { $0.url.scheme == "https" })
    }

    @Test func lightingSummaryDescribesTheFace() {
        let night = OrlojDialLighting(sunAltitudeDegrees: -30, sunAzimuthDegrees: 0, latitudeDegrees: 50.09)
        let shade = OrlojDialLighting(sunAltitudeDegrees: 8, sunAzimuthDegrees: 295, latitudeDegrees: 50.09)
        let winterNoon = OrlojDialLighting(sunAltitudeDegrees: 16.5, sunAzimuthDegrees: 180, latitudeDegrees: 50.09)
        let summerNoon = OrlojDialLighting(sunAltitudeDegrees: 63.3, sunAzimuthDegrees: 180, latitudeDegrees: 50.09)
        let morning = OrlojDialLighting(sunAltitudeDegrees: 30, sunAzimuthDegrees: 130, latitudeDegrees: 50.09)
        #expect(night.summary.hasPrefix("Night"))
        #expect(shade.summary.hasPrefix("Face in shade"))
        #expect(winterNoon.summary.hasPrefix("Short shadows fall straight down"))
        #expect(summerNoon.summary.hasPrefix("Long shadows fall straight down"))
        #expect(morning.summary.contains("to the left"))
    }
}
