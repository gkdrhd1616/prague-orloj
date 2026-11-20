import Foundation
import Testing
@testable import astologia_hologia

/// The app follows the system language: English source text, Korean translation.
/// These read the Korean strings the app actually ships.
struct OrlojKoreanLocalizationTests {
    private func koreanBundle() throws -> Bundle {
        let path = try #require(Bundle.main.path(forResource: "ko", ofType: "lproj"))
        return try #require(Bundle(path: path))
    }

    private func korean(_ english: String, _ bundle: Bundle) -> String {
        NSLocalizedString(english, bundle: bundle, comment: "")
    }

    @Test func appShipsKoreanStrings() throws {
        let ko = try koreanBundle()
        #expect(korean("Sun", ko) == "태양")
        #expect(korean("Reading guide", ko) == "읽는 법")
        #expect(korean("Prague Orloj", ko) == "프라하 오를로이")
    }

    @Test func everyGuideTextHasAKoreanTranslation() throws {
        let ko = try koreanBundle()
        var texts = OrlojGuideCatalog.quickSteps + [
            OrlojGuideCatalog.overview, OrlojGuideCatalog.history,
            OrlojGuideCatalog.pragueModeNote, OrlojGuideCatalog.mySkyModeNote,
            OrlojGuideCatalog.creditNote
        ]
        texts += OrlojGuideCatalog.sources.map(\.title)
        texts += OrlojGuideSection.allCases.map(\.rawValue)
        for item in OrlojGuideCatalog.items {
            texts += [item.title, item.shortDescription] + item.readingSteps
            texts += [item.subtitle, item.longDescription, item.pragueNote, item.calloutLabel].compactMap { $0 }
        }
        for text in texts {
            #expect(korean(text, ko) != text, "No Korean for: \(text)")
        }
    }

    @Test func everyMenuAndStateNameHasAKoreanTranslation() throws {
        let ko = try koreanBundle()
        var names = OrlojLayerFocus.allCases.map(\.rawValue)
        names += OrlojDialMode.allCases.map(\.rawValue)
        names += OrlojDrawerTab.allCases.map(\.rawValue)
        names += ZodiacSign.all.map(\.name)
        names += ["New", "Waxing crescent", "First quarter", "Waxing gibbous",
                  "Full", "Waning gibbous", "Last quarter", "Waning crescent"]
        names += ["Day", "Twilight", "Night", "Polar day", "Dial time", "Apparent solar time"]
        for name in names {
            #expect(korean(name, ko) != name, "No Korean for: \(name)")
        }
    }

    @Test func koreanFormatsKeepTheirValuesInOrder() throws {
        let ko = try koreanBundle()
        #expect(String(format: korean("Hour %@", ko), "3") == "3시")
        #expect(String(format: korean("%1$@ shadows fall %2$@", ko), "길게", "바로 아래로") == "그림자가 바로 아래로 길게 드리웁니다")
        #expect(String(format: korean("Sky: %1$@ · altitude %2$@", ko), "게자리", "45°") == "하늘: 게자리 · 고도 45°")
    }
}
