import SwiftUI
import WidgetKit

private struct PragueOrlojEntry: TimelineEntry {
    let date: Date
    let location: OrlojWidgetLocationSnapshot?
    let clockState: OrlojClockState?

    init(date: Date, location: OrlojWidgetLocationSnapshot? = .current) {
        self.date = date
        self.location = location
        self.clockState = Self.makeClockState(for: date, location: location)
    }

    private static func makeClockState(for date: Date, location: OrlojWidgetLocationSnapshot?) -> OrlojClockState? {
        guard let location else { return nil }
        let clockLocation: OrlojClockLocation
        if location.usesPragueMechanism {
            clockLocation = .prague
        } else {
            clockLocation = .detected(
                name: location.name,
                coordinates: OrlojCoordinates(latitude: location.latitude, longitude: location.longitude),
                timeZone: location.timeZone
            )
        }
        return OrlojCalculator.state(for: date, location: clockLocation)
    }
}

private struct PragueOrlojProvider: TimelineProvider {
    func placeholder(in context: Context) -> PragueOrlojEntry {
        PragueOrlojEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PragueOrlojEntry) -> Void) {
        completion(PragueOrlojEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PragueOrlojEntry>) -> Void) {
        let now = Date.now
        let entry = PragueOrlojEntry(date: now)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = entry.location?.timeZone ?? .autoupdatingCurrent
        let refresh = calendar.nextDate(
            after: now,
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

private struct PragueOrlojWidgetView: View {
    let entry: PragueOrlojEntry

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let state = entry.clockState {
                    OrlojClockView(state: state)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    VStack(spacing: 5) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(OrlojDesignSystem.gold)
                        Text("OPEN APP TO SET LOCATION")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(OrlojDesignSystem.ivoryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(OrlojDesignSystem.background)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .containerBackground(OrlojDesignSystem.background, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        guard let state = entry.clockState, let location = entry.location else {
            return "Open the astronomical clock app to set a location"
        }
        return "Prague astronomical clock dial, current sky for \(location.name), local time \(state.localTimeString), apparent solar time \(state.dialTimeString)"
    }
}

@main
struct PragueOrlojWidget: Widget {
    private let kind = "PragueOrlojWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PragueOrlojProvider()) { entry in
            PragueOrlojWidgetView(entry: entry)
        }
        .configurationDisplayName("Astronomical Clock · 2×2")
        .description("The full astronomical dial, calculated for your current location and sky.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
