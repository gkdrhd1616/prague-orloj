import Foundation

/// The minimum location and time-zone context shared with the WidgetKit process.
/// Coordinates are kept only so the host app can restore its selected location.
struct OrlojWidgetLocationSnapshot: Codable, Equatable {
    static let appGroupIdentifier = "group.com.shubeux.astologiahologia.v1"
    static let defaultsKey = "orloj.widget.location.v1"

    let name: String
    let timeZoneIdentifier: String
    let latitude: Double
    let longitude: Double
    let mode: String

    var usesPragueMechanism: Bool { mode == "prague" }

    var timeZone: TimeZone {
        if usesPragueMechanism, let cet = TimeZone(secondsFromGMT: 60 * 60) {
            return cet
        }
        return TimeZone(identifier: timeZoneIdentifier) ?? .autoupdatingCurrent
    }

    static var current: OrlojWidgetLocationSnapshot? {
        guard let data = UserDefaults(suiteName: appGroupIdentifier)?.data(forKey: defaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.appGroupIdentifier)?.set(data, forKey: Self.defaultsKey)
    }
}
