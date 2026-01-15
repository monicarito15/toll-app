//
//  MapViewModel.swift
//  toll-app
//
//  Created by Carolina Mera on 09/10/2025.
//  ViewModel: contiene la lógica de ubicación, rutas y tolls.


import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    
    
    @Published var route: MKRoute? // Ruta calculada.
    @Published var toll: [Vegobjekt] = [] // Lista de tolls desde la API.
    @Published var userLocation: CLLocationCoordinate2D? // Ubicación actual del usuario.
    @Published var originCoordinate: CLLocationCoordinate2D? // From routa
    
    // Para la barrita + sheet
        @Published var hasResult: Bool = false
        @Published var totalPrice: Double = 0
        @Published var tollsOnRoute: [Vegobjekt] = []
    
    private let locationManager = LocationManager()
    
    func resetResult() {
            hasResult = false
            totalPrice = 0
            tollsOnRoute = []
            route = nil
        }
    
    // Copia la ubicación del usuario desde locationManager.
    func updateUserLocation() {
        userLocation = locationManager.userLocation
    }
    
    // Obtiene los tolls desde la API.
    func fetchTolls() async {
        do {
            toll = try await TollService.shared.getTolls()
        } catch {
            print(" Error to fetch tolls: \(error)")
        }
    }
    
    // Funcion que calcula la ruta entre dos coordenadas (from - to).
    func getDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: .init(coordinate: from))
        request.destination = MKMapItem(placemark: .init(coordinate: to))
        request.transportType = .automobile
        
        do {
            let directions = try await MKDirections(request: request).calculate()
            if let firstRoute = directions.routes.first {
                print("Distance: \(firstRoute.distance) m")
                print("Estimated duration: \(firstRoute.expectedTravelTime) seconds")
                route = firstRoute
            } else {
                print("No route found.")
            }
        } catch {
            print("Error calculating directions: \(error)")
        }
    }
    
    
    
    // Convierte la dirección textual del destino a coordenadas (Geocoding).
    // Luego calcula la ruta desde la ubicación actual hacia esa dirección.
    func geocode(from: CLLocationCoordinate2D, toAddress: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(toAddress) { placemarks, error in
            if let error = error {
                print("Geocoder Error: \(error)")
                return
            }
            if let destination = placemarks?.first?.location?.coordinate {
                Task {
                    await self.getDirections(from: from, to: destination)
                }
            } else {
                
                
                print("No coordinate found for address: \(toAddress)")
            }
        }
    }
    // Helper mínimo: address -> coordinate
        private func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    print("Geocoder Error: \(error)")
                    completion(nil)
                    return
                }
                completion(placemarks?.first?.location?.coordinate)
            }
        }
    
    
    func getDirectionsFromAddresses(fromAddress: String, toAddress: String) async {
        
        let fromTrim = fromAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                let toTrim = toAddress.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !toTrim.isEmpty else {
                    print("Missing 'to' address")
                    return
        }
        // 1) Geocode TO
        geocodeAddress(toTrim) { destination in
            guard let destination else {
                print("No coordinate found for TO: \(toTrim)")
                return
            }
            
            // 2) Origin = userLocation o geocode FROM
            if fromTrim.isEmpty {
                // usa la ubicacion del usuario como origen
                self.updateUserLocation()
                guard let origin = self.userLocation else {
                    print("No user location yet")
                    return
                }
                // Publica el origen para que  la vista pueda mover la camara
                self.originCoordinate = origin
                
                Task { @MainActor in
                    await self.getDirections(from: origin, to: destination)
                }
                
            } else {
                self.geocodeAddress(fromTrim) { origin in
                    guard let origin else {
                        print ("No coordinate found for FROM: \(fromTrim)")
                        return
                    }
                    // Publica el origen para que  la vista pueda mover la camara
                    self.originCoordinate = origin
                    Task { @MainActor in
                        await self.getDirections(from: origin, to: destination)
                    }
                }
            }
            
        }
    }
    
    // detectar tolls en la ruta (precio por ahora 0)
       func buildResultIfPossible(vehicle: VehicleType, fuel: FuelType, date: Date) {
           guard let route else { return }
           guard !toll.isEmpty else { return }

           tollsOnRoute = tollsNearRoute(route: route, tolls: toll, maxDistanceMeters: 350)
           totalPrice = 0
           hasResult = true
       }
    
    private func tollsNearRoute(route: MKRoute, tolls: [Vegobjekt], maxDistanceMeters: Double) -> [Vegobjekt] {
        let polyline = route.polyline
        let routePoints = samplePolylinePoints(polyline, step: 25) // step más bajo = más exacto

        return tolls.filter { toll in
            guard let c = toll.lokasjon?.coordinates else { return false }
            let tollLoc = CLLocation(latitude: c.latitude, longitude: c.longitude)

            for p in routePoints {
                let d = tollLoc.distance(from: CLLocation(latitude: p.latitude, longitude: p.longitude))
                if d <= maxDistanceMeters { return true }
            }
            return false
        }
    }

    private func samplePolylinePoints(_ polyline: MKPolyline, step: Int) -> [CLLocationCoordinate2D] {
        let count = polyline.pointCount
        guard count > 0 else { return [] }

        var coords = Array(repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0), count: count)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))

        guard step > 1 else { return coords }

        var sampled: [CLLocationCoordinate2D] = []
        for i in stride(from: 0, to: count, by: step) {
            sampled.append(coords[i])
        }
        if let last = coords.last { sampled.append(last) }
        return sampled
    }


    
}

