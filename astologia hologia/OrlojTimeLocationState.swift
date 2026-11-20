//
//  OrlojTimeLocationState.swift
//  astologia hologia
//
//  Created by Codex on 5/13/26.
//

import Foundation

enum OrlojTimeMode: String, CaseIterable, Identifiable {
    case live
    case manual

    var id: String {
        rawValue
    }
}

struct OrlojTimeState: Equatable {
    var mode: OrlojTimeMode
    var manualDateTime: Date?

    static let live = OrlojTimeState(mode: .live, manualDateTime: nil)

    static func manual(_ date: Date) -> OrlojTimeState {
        OrlojTimeState(mode: .manual, manualDateTime: date)
    }

    var isLive: Bool {
        mode == .live
    }

    func resolvedDate(liveDate: Date) -> Date {
        switch mode {
        case .live:
            liveDate
        case .manual:
            manualDateTime ?? liveDate
        }
    }

    mutating func useLiveNow() {
        mode = .live
        manualDateTime = nil
    }

    mutating func useManual(_ date: Date) {
        mode = .manual
        manualDateTime = date
    }
}

enum OrlojLocationMode: String, CaseIterable, Identifiable {
    case prague
    case device
    case manual

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .prague:
            orlojLocalized("Prague Orloj")
        case .device:
            orlojLocalized("My device sky")
        case .manual:
            orlojLocalized("Manual sky")
        }
    }
}

enum OrlojLocationBasis: String, Equatable {
    case praguePreset = "prague-preset"
    case gps
    case manual

    var label: String {
        switch self {
        case .praguePreset:
            orlojLocalized("Prague Orloj preset")
        case .gps:
            orlojLocalized("GPS")
        case .manual:
            orlojLocalized("Manual")
        }
    }
}

enum OrlojLocationPrecision: String, Equatable {
    case exact
    case precise
    case approximate

    var label: String {
        switch self {
        case .exact:
            orlojLocalized("Exact")
        case .precise:
            orlojLocalized("Precise")
        case .approximate:
            orlojLocalized("Approximate")
        }
    }
}

struct OrlojLocationFix: Equatable {
    let location: OrlojClockLocation
    let precision: OrlojLocationPrecision
    let horizontalAccuracyMeters: Double

    var statusMessage: String {
        let accuracy = horizontalAccuracyMeters.formatted(.number.precision(.fractionLength(horizontalAccuracyMeters < 1_000 ? 0 : 1)))
        let unitValue = horizontalAccuracyMeters < 1_000
            ? "\(accuracy) m"
            : "\((horizontalAccuracyMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km"
        return orlojLocalized("Using device location · ±%@", unitValue)
    }
}

struct OrlojLocationRequestGate: Equatable {
    private(set) var activeRequestID: UUID?

    mutating func begin() -> UUID {
        let requestID = UUID()
        activeRequestID = requestID
        return requestID
    }

    mutating func cancel() {
        activeRequestID = nil
    }

    func accepts(_ requestID: UUID) -> Bool {
        activeRequestID == requestID
    }
}

struct OrlojLocationState: Equatable {
    var mode: OrlojLocationMode
    var basis: OrlojLocationBasis
    var label: String
    var latitude: Double
    var longitude: Double
    var timezone: String
    var precision: OrlojLocationPrecision?
    var horizontalAccuracyMeters: Double?
    var statusMessage: String?

    static let prague = OrlojLocationState(
        mode: .prague,
        basis: .praguePreset,
        label: "Prague Orloj",
        latitude: OrlojCoordinates.prague.latitude,
        longitude: OrlojCoordinates.prague.longitude,
        timezone: OrlojClockLocation.prague.timeZone.identifier,
        precision: .exact,
        horizontalAccuracyMeters: nil,
        statusMessage: orlojLocalized("Location basis: Prague preset")
    )

    static let currentLocationPending = OrlojLocationState(
        mode: .device,
        basis: .gps,
        label: "Current Location",
        latitude: 0,
        longitude: 0,
        timezone: TimeZone.autoupdatingCurrent.identifier,
        precision: nil,
        horizontalAccuracyMeters: nil,
        statusMessage: orlojLocalized("Finding current location…")
    )

    init(
        mode: OrlojLocationMode,
        basis: OrlojLocationBasis,
        label: String,
        latitude: Double,
        longitude: Double,
        timezone: String,
        precision: OrlojLocationPrecision? = nil,
        horizontalAccuracyMeters: Double? = nil,
        statusMessage: String? = nil
    ) {
        self.mode = mode
        self.basis = basis
        self.label = label
        self.latitude = latitude.clamped(to: -90...90)
        self.longitude = longitude.clamped(to: -180...180)
        self.timezone = timezone
        self.precision = precision
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.statusMessage = statusMessage
    }

    init(
        location: OrlojClockLocation,
        mode: OrlojLocationMode,
        basis: OrlojLocationBasis,
        label: String? = nil,
        precision: OrlojLocationPrecision? = nil,
        horizontalAccuracyMeters: Double? = nil,
        statusMessage: String? = nil
    ) {
        self.init(
            mode: mode,
            basis: basis,
            label: label ?? location.name,
            latitude: location.coordinates.latitude,
            longitude: location.coordinates.longitude,
            timezone: location.timeZone.identifier,
            precision: precision,
            horizontalAccuracyMeters: horizontalAccuracyMeters,
            statusMessage: statusMessage
        )
    }

    var coordinates: OrlojCoordinates {
        get {
            OrlojCoordinates(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude.clamped(to: -90...90)
            longitude = newValue.longitude.clamped(to: -180...180)
        }
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timezone) ?? OrlojClockLocation.prague.timeZone
    }

    var conceptualModeTitle: String {
        switch mode {
        case .prague:
            orlojLocalized("Prague Orloj")
        case .device, .manual:
            orlojLocalized("My Sky")
        }
    }

    var conceptualModeDetail: String {
        switch mode {
        case .prague:
            orlojLocalized("Historical Prague astronomical clock location")
        case .device:
            orlojLocalized("Personal sky from device location")
        case .manual:
            orlojLocalized("Personal sky from manual location")
        }
    }

    var precisionLabel: String {
        guard let precision else {
            return orlojLocalized("Unspecified")
        }
        guard let horizontalAccuracyMeters else {
            return precision.label
        }

        let accuracy = horizontalAccuracyMeters < 1_000
            ? "\(horizontalAccuracyMeters.formatted(.number.precision(.fractionLength(0)))) m"
            : "\((horizontalAccuracyMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km"
        return orlojLocalized("%1$@ · ±%2$@", precision.label, accuracy)
    }

    var resolvedLocation: OrlojClockLocation {
        switch mode {
        case .prague:
            return OrlojClockLocation(
                id: OrlojClockLocation.prague.id,
                name: trimmedLabel(fallback: "Prague Orloj"),
                detail: OrlojClockLocation.prague.detail,
                coordinates: .prague,
                timeZone: OrlojClockLocation.prague.timeZone
            )
        case .device:
            return .detected(
                name: trimmedLabel(fallback: "Device location"),
                coordinates: coordinates,
                timeZone: timeZone
            )
        case .manual:
            return .custom(
                name: trimmedLabel(fallback: "Manual"),
                coordinates: coordinates,
                timeZone: timeZone
            )
        }
    }

    mutating func applyPraguePreset(statusMessage: String? = orlojLocalized("Location basis: Prague preset")) {
        self = .prague
        self.statusMessage = statusMessage
    }

    mutating func applyManualPreset(_ location: OrlojClockLocation) {
        self = OrlojLocationState(
            location: location,
            mode: .manual,
            basis: .manual,
            precision: .exact,
            horizontalAccuracyMeters: nil,
            statusMessage: orlojLocalized("Location basis: Manual")
        )
    }

    mutating func applyDeviceGPS(_ fix: OrlojLocationFix) {
        mode = .device
        basis = .gps
        label = fix.location.name
        coordinates = fix.location.coordinates
        timezone = fix.location.timeZone.identifier
        precision = fix.precision
        horizontalAccuracyMeters = fix.horizontalAccuracyMeters
        statusMessage = fix.statusMessage
    }

    mutating func updateTimeZone(_ identifier: String) {
        timezone = identifier
        markManual()
    }

    mutating func updateLatitude(_ latitude: Double) {
        self.latitude = latitude.clamped(to: -90...90)
        markManual()
    }

    mutating func updateLongitude(_ longitude: Double) {
        self.longitude = longitude.clamped(to: -180...180)
        markManual()
    }

    mutating func markManual() {
        mode = .manual
        basis = .manual
        label = "Manual"
        precision = .exact
        horizontalAccuracyMeters = nil
        statusMessage = orlojLocalized("Location basis: Manual")
    }

    mutating func recordLocationRequestFailure(_ message: String) {
        statusMessage = message
    }

    private func trimmedLabel(fallback: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
