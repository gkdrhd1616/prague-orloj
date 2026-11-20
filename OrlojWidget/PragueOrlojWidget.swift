import SwiftUI
import WidgetKit

private struct PragueOrlojEntry: TimelineEntry {
    let date: Date
    let location: OrlojWidgetLocationSnapshot?
    // Keep future entries small. The app's curve cache is shared by all dates
    // at the same location; each view calculates only the state it displays.
    var clockState: OrlojClockState? {
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
        let place = OrlojClockLocation.prague
        let sample = OrlojWidgetLocationSnapshot(
            name: place.name, timeZoneIdentifier: place.timeZone.identifier,
            latitude: place.coordinates.latitude, longitude: place.coordinates.longitude, mode: "prague"
        )
        return PragueOrlojEntry(date: .now, location: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (PragueOrlojEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(PragueOrlojEntry(date: .now, location: .current))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PragueOrlojEntry>) -> Void) {
        let now = Date.now
        let location = OrlojWidgetLocationSnapshot.current
        var entries = [PragueOrlojEntry(date: now, location: location)]
        guard location != nil else {
            // Selecting a location in the app explicitly reloads the widget.
            completion(Timeline(entries: entries, policy: .never))
            return
        }

        // Schedule five-minute dial positions two hours ahead. Ask for more
        // after one hour so a delayed reload still has positions to display.
        let interval: TimeInterval = 5 * 60
        let slot = floor(now.timeIntervalSinceReferenceDate / interval)
        for offset in 1...24 {
            let date = Date(timeIntervalSinceReferenceDate: (slot + Double(offset)) * interval)
            entries.append(PragueOrlojEntry(date: date, location: location))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
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
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Astronomical clock for \(orlojLocalized(state.location.name))")
                        .accessibilityValue("Local time \(state.localTimeString), dial \(state.dialTimeString) \(state.dialTimeZoneLabel), \(state.skyPhaseLabel), \(orlojLocalized(state.lunar.phaseName))")
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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Open the astronomical clock app to set a location")
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .containerBackground(OrlojDesignSystem.background, for: .widget)
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
