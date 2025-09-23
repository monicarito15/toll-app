//
//  LocationManager.swift
//  toll-app
//
//  Created by Carolina Mera  on 18/09/2025.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var currentAddress: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,didUpdateLocations locations: [CLLocation]){
        if let location = locations.last{
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
                self.reverseGeocode(location: location) // convertir coordenadas para mostar direccion d la locacion
            }
            
        }
    }
    
    func requestLocation(){
        manager.requestLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    func reverseGeocode(location: CLLocation){
        geocoder.reverseGeocodeLocation(location) { placemark, error in
            if let placemark = placemark?.first{
                DispatchQueue.main.async {
                    self.currentAddress = [
                        placemark.name,
                        placemark.locality,
                        placemark.country
                    ]
                        .compactMap { $0 }
                        .joined(separator: " , ")
                }
                
            }
            
        }
    }
}
