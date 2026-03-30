//
//  LocationManager.swift
//  toll-app
//
//  Created by Carolina Mera  on 18/09/2025.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - CoreLocation objects
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: - Published state
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var currentAddress: String?

    // MARK: - Init
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = manager.authorizationStatus
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    // MARK: - Delegate: didUpdateLocations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
                #if DEBUG
                print("didUpdateLocations -> \(location.coordinate.latitude), \(location.coordinate.longitude)")
                #endif
                self.reverseGeocode(location: location)
            }
        }
    }

    // MARK: - Public: requestLocation
    func requestLocation() {
        let status = manager.authorizationStatus

        #if DEBUG
        print("requestLocation() tapped. authStatus = \(status.rawValue)")
        #endif

        if status == .notDetermined {
            requestAuthorization()
            return
        }

        if status == .denied || status == .restricted {
            #if DEBUG
            print("Location permission denied/restricted")
            #endif
            return
        }

        manager.requestLocation()
    }

    // MARK: - Delegate: didFailWithError
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        DispatchQueue.main.async {
            print("Location error: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Public: requestAuthorization
    func requestAuthorization() {
        #if DEBUG
        print("Requesting WhenInUse authorization...")
        #endif
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Delegate: authorization changed
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            #if DEBUG
            print("Authorization changed -> \(manager.authorizationStatus.rawValue)")
            #endif
        }
    }

    // MARK: - reverseGeocoding
    func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemark, error in
            if let error = error {
                #if DEBUG
                print("ReverseGeocode error: \(error.localizedDescription)")
                #endif
                return
            }

            if let placemark = placemark?.first {
                DispatchQueue.main.async {
                    self.currentAddress = [
                        placemark.name,
                        placemark.locality,
                        placemark.country
                    ]
                    .compactMap { $0 }
                    .joined(separator: " , ")

                    #if DEBUG
                    print("currentAddress set -> \(self.currentAddress ?? "nil")")
                    #endif
                }
            } else {
                #if DEBUG
                print("ReverseGeocode: no placemark found")
                #endif
            }
        }
    }
}
