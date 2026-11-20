//
//  OrlojLocationProvider.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import Combine
import CoreLocation
import Foundation
import MapKit

final class OrlojLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private enum RequestPhase: Equatable {
        case idle
        case awaitingAuthorization
        case requestingLocation
        case resolvingLocation
    }

    @Published var isLocating = false
    @Published var statusMessage = "Device location not requested"

    private lazy var manager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        return manager
    }()
    private var reverseGeocodingRequest: MKReverseGeocodingRequest?
    private var requestGate = OrlojLocationRequestGate()
    private var requestPhase = RequestPhase.idle
    private var applyLocation: ((OrlojLocationFix) -> Void)?
    private var applyFailure: ((String) -> Void)?

    func requestCurrentLocation(
        apply: @escaping (OrlojLocationFix) -> Void,
        failure: @escaping (String) -> Void
    ) {
        cancelCurrentRequest()
        let requestID = requestGate.begin()
        applyLocation = apply
        applyFailure = failure
        isLocating = true
        statusMessage = "Checking device location..."

        switch manager.authorizationStatus {
        case .notDetermined:
            requestPhase = .awaitingAuthorization
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            requestPhase = .requestingLocation
            manager.requestLocation()
        case .denied, .restricted:
            finishWithFailure(requestID: requestID, message: "Device location unavailable. Keeping the current location.")
        @unknown default:
            finishWithFailure(requestID: requestID, message: "Device location unavailable. Keeping the current location.")
        }
    }

    func cancelCurrentRequest() {
        requestGate.cancel()
        manager.stopUpdatingLocation()
        reverseGeocodingRequest?.cancel()
        reverseGeocodingRequest = nil
        applyLocation = nil
        applyFailure = nil
        isLocating = false
        requestPhase = .idle
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let requestID = requestGate.activeRequestID,
              requestPhase == .awaitingAuthorization else {
            return
        }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestPhase = .requestingLocation
            manager.requestLocation()
        case .denied, .restricted:
            finishWithFailure(requestID: requestID, message: "Device location unavailable. Keeping the current location.")
        case .notDetermined:
            break
        @unknown default:
            finishWithFailure(requestID: requestID, message: "Device location unavailable. Keeping the current location.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let requestID = requestGate.activeRequestID,
              requestPhase == .requestingLocation else {
            return
        }
        guard let location = locations.last else {
            finishWithFailure(requestID: requestID, message: "Device location unavailable. Keeping the current location.")
            return
        }
        guard location.horizontalAccuracy >= 0 else {
            finishWithFailure(requestID: requestID, message: "Device returned an invalid location. Keeping the current location.")
            return
        }

        requestPhase = .resolvingLocation
        resolve(location, requestID: requestID)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let requestID = requestGate.activeRequestID,
              requestPhase == .requestingLocation else {
            return
        }
        finishWithFailure(requestID: requestID, message: "Device location unavailable. Keeping the current location.")
    }

    private func resolve(_ location: CLLocation, requestID: UUID) {
        let coordinates = OrlojCoordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        let precision = Self.precision(for: manager.accuracyAuthorization)
        let horizontalAccuracy = location.horizontalAccuracy
        guard let request = MKReverseGeocodingRequest(location: location) else {
            finishWithFailure(requestID: requestID, message: "Could not resolve the device location. Keeping the current location.")
            return
        }
        reverseGeocodingRequest = request
        request.getMapItems { [weak self] mapItems, _ in
            guard let self, self.requestGate.accepts(requestID) else {
                return
            }

            let mapItem = mapItems?.first
            let timeZone = mapItem?.timeZone ?? .current
            let placeName = mapItem?.addressRepresentations?.cityName
                ?? mapItem?.addressRepresentations?.regionName
                ?? "Current Location"
            let detected = OrlojClockLocation.detected(
                name: placeName,
                coordinates: coordinates,
                timeZone: timeZone
            )
            let fix = OrlojLocationFix(
                location: detected,
                precision: precision,
                horizontalAccuracyMeters: horizontalAccuracy
            )

            self.reverseGeocodingRequest = nil
            self.finishWithSuccess(requestID: requestID, fix: fix)
        }
    }

    private func finishWithSuccess(requestID: UUID, fix: OrlojLocationFix) {
        guard requestGate.accepts(requestID) else {
            return
        }
        applyLocation?(fix)
        requestGate.cancel()
        applyLocation = nil
        applyFailure = nil
        isLocating = false
        requestPhase = .idle
        statusMessage = fix.statusMessage
    }

    private func finishWithFailure(requestID: UUID, message: String) {
        guard requestGate.accepts(requestID) else {
            return
        }
        applyFailure?(message)
        requestGate.cancel()
        applyLocation = nil
        applyFailure = nil
        isLocating = false
        requestPhase = .idle
        statusMessage = message
    }

    static func precision(for authorization: CLAccuracyAuthorization) -> OrlojLocationPrecision {
        authorization == .reducedAccuracy ? .approximate : .precise
    }
}
