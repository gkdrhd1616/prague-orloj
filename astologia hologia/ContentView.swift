//
//  ContentView.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var timeState = OrlojTimeState.live
    @State private var isDrawerPresented: Bool
    @State private var selectedDrawerTab: OrlojDrawerTab
    @State private var dialFocus = OrlojDialFocusState.display
    @State private var locationState: OrlojLocationState
    @State private var hasResolvedLocation: Bool
    @State private var didRequestInitialLocation = false
    @StateObject private var locationProvider = OrlojLocationProvider()
    private let isUITesting: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        #if DEBUG
        isUITesting = arguments.contains { $0.hasPrefix("-uiTesting") }
        #else
        isUITesting = false
        #endif
        if isUITesting {
            let missing = arguments.contains("-uiTestingMissingLocation")
            _locationState = State(initialValue: missing ? .currentLocationPending : .prague)
            _hasResolvedLocation = State(initialValue: !missing)
        } else {
            let savedLocation = OrlojWidgetLocationSnapshot.current
            _locationState = State(initialValue: Self.restoredLocation(from: savedLocation))
            _hasResolvedLocation = State(initialValue: savedLocation != nil)
        }
        _isDrawerPresented = State(initialValue: arguments.contains("-uiTestingOpenDrawer"))
        _selectedDrawerTab = State(initialValue: OrlojDrawerTab.launchArgumentValue(in: arguments) ?? .settings)
        #if DEBUG
        if let index = arguments.firstIndex(of: "-uiTestingDate"),
           arguments.indices.contains(index + 1),
           let date = ISO8601DateFormatter().date(from: arguments[index + 1]) {
            _timeState = State(initialValue: .manual(date))
        }
        #endif
    }

    var body: some View {
        TimelineView(.everyMinute) { _ in
            // The first scheduled entry is rounded down; use the actual instant
            // for the first drawing and when returning to the foreground.
            let activeDate = timeState.resolvedDate(liveDate: .now)
            let state = hasResolvedLocation ? state(for: activeDate) : nil

            OrlojScreen(
                state: state,
                readout: state.map { OrlojAstronomyReadout(state: $0) },
                timeState: $timeState,
                locationState: locationSelection,
                isDrawerPresented: $isDrawerPresented,
                selectedDrawerTab: $selectedDrawerTab,
                dialFocus: $dialFocus,
                isLocating: locationProvider.isLocating,
                locationStatusMessage: displayedLocationStatus,
                selectLocationMode: selectLocationMode,
                confirmManualLocation: { hasResolvedLocation = true }
            )
        }
        .onAppear(perform: requestInitialLocationIfNeeded)
        .onChange(of: widgetLocation) { _, snapshot in
            guard !isUITesting, let snapshot else { return }
            snapshot.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private static func restoredLocation(from snapshot: OrlojWidgetLocationSnapshot?) -> OrlojLocationState {
        guard let snapshot else { return .currentLocationPending }
        if snapshot.usesPragueMechanism { return .prague }
        return OrlojLocationState(
            mode: snapshot.mode == OrlojLocationMode.manual.rawValue ? .manual : .device,
            basis: snapshot.mode == OrlojLocationMode.manual.rawValue ? .manual : .gps,
            label: snapshot.name,
            latitude: snapshot.latitude,
            longitude: snapshot.longitude,
            timezone: snapshot.timeZoneIdentifier,
            precision: nil,
            horizontalAccuracyMeters: nil,
            statusMessage: "Using saved location · \(snapshot.timeZone.abbreviation() ?? snapshot.timeZoneIdentifier)"
        )
    }

    private func requestInitialLocationIfNeeded() {
        guard !didRequestInitialLocation,
              !isUITesting,
              locationState.mode == .device else { return }
        didRequestInitialLocation = true
        requestCurrentLocation()
    }

    private var widgetLocation: OrlojWidgetLocationSnapshot? {
        guard hasResolvedLocation else { return nil }
        let state = locationState
        return OrlojWidgetLocationSnapshot(
            name: state.mode == .prague ? "Prague" : state.label,
            timeZoneIdentifier: state.mode == .prague
                ? OrlojClockLocation.prague.timeZone.identifier
                : state.timezone,
            latitude: state.mode == .prague ? OrlojCoordinates.prague.latitude : state.latitude,
            longitude: state.mode == .prague ? OrlojCoordinates.prague.longitude : state.longitude,
            mode: state.mode.rawValue
        )
    }

    private func state(for date: Date) -> OrlojClockState {
        OrlojCalculator.state(
            for: date,
            location: locationState.resolvedLocation
        )
    }

    private var locationSelection: Binding<OrlojLocationState> {
        Binding(
            get: { locationState },
            set: { newLocation in
                // A manual edit takes precedence over an in-flight GPS lookup.
                locationProvider.cancelCurrentRequest()
                locationState = newLocation
            }
        )
    }

    private func requestCurrentLocation() {
        locationProvider.requestCurrentLocation(
            apply: { fix in
                locationState.applyDeviceGPS(fix)
                hasResolvedLocation = true
            },
            failure: { message in
                locationState.recordLocationRequestFailure(hasResolvedLocation ? message : "Location unavailable. Allow location access or choose a location in Settings.")
            }
        )
    }

    private func selectLocationMode(_ mode: OrlojLocationMode) {
        switch mode {
        case .prague:
            locationProvider.cancelCurrentRequest()
            locationState.applyPraguePreset()
            hasResolvedLocation = true
        case .device:
            requestCurrentLocation()
        case .manual:
            locationProvider.cancelCurrentRequest()
            locationState.markManual()
        }
    }

    private var displayedLocationStatus: String {
        if locationProvider.isLocating {
            return locationProvider.statusMessage
        }

        if let message = locationState.statusMessage {
            return message
        }

        switch locationState.basis {
        case .praguePreset:
            return "Mode: Prague Orloj"
        case .gps:
            return locationState.statusMessage ?? "My Sky: device location"
        case .manual:
            return "Mode: My Sky manual"
        }
    }
}

private struct OrlojPreviewHost: View {
    @State private var timeState = OrlojTimeState.manual(Date(timeIntervalSince1970: 1_778_032_800))
    @State private var isDrawerPresented: Bool
    @State private var selectedDrawerTab: OrlojDrawerTab
    @State private var dialFocus = OrlojDialFocusState.display
    @State private var locationState = OrlojLocationState.prague

    init(isDrawerPresented: Bool = false, selectedDrawerTab: OrlojDrawerTab = .settings) {
        _isDrawerPresented = State(initialValue: isDrawerPresented)
        _selectedDrawerTab = State(initialValue: selectedDrawerTab)
    }

    private var previewState: OrlojClockState {
        OrlojCalculator.state(
            for: timeState.resolvedDate(liveDate: Date()),
            location: locationState.resolvedLocation
        )
    }

    var body: some View {
        OrlojScreen(
            state: previewState,
            readout: OrlojAstronomyReadout(state: previewState),
            timeState: $timeState,
            locationState: $locationState,
            isDrawerPresented: $isDrawerPresented,
            selectedDrawerTab: $selectedDrawerTab,
            dialFocus: $dialFocus,
            isLocating: false,
            locationStatusMessage: "Mode: Prague Orloj",
            selectLocationMode: selectPreviewLocationMode
        )
    }

    private func selectPreviewLocationMode(_ mode: OrlojLocationMode) {
        switch mode {
        case .prague:
            locationState.applyPraguePreset()
        case .device:
            locationState.recordLocationRequestFailure("Device location is unavailable in previews.")
        case .manual:
            locationState.markManual()
        }
    }
}

#Preview("Closed") {
    OrlojPreviewHost()
}

#Preview("Settings") {
    OrlojPreviewHost(isDrawerPresented: true, selectedDrawerTab: .settings)
}

#Preview("Astronomy") {
    OrlojPreviewHost(isDrawerPresented: true, selectedDrawerTab: .astronomy)
}

#Preview("Guide") {
    OrlojPreviewHost(isDrawerPresented: true, selectedDrawerTab: .guide)
}
