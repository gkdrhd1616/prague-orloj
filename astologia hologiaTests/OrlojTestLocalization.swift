import Foundation
@testable import astologia_hologia

private final class SourceLanguageMarker {}

extension OrlojLocalization {
    /// Reads every string in its English source form, so tests that compare
    /// labels pass whatever language the simulator uses. The test bundle has
    /// no string catalog, so each lookup returns its English key.
    static func useSourceLanguageForTests() {
        bundle = Bundle(for: SourceLanguageMarker.self)
    }
}
