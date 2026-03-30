
//  ViewModel: contiene la lógica de ubicación, rutas y tolls desde NVDB, hasResult(muestra la barra despues del calculo).


import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    
    
    @Published var route: MKRoute?
    @Published var toll: [Vegobjekt] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var originCoordinate: CLLocationCoordinate2D?
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    
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
        originCoordinate = nil
        destinationCoordinate = nil
    }
    
    func updateUserLocation() {
        userLocation = locationManager.userLocation
    }
    
    func fetchTolls() async {
        do {
            toll = try await TollService.shared.getTolls()
        } catch {
            #if DEBUG
            print("Error to fetch tolls: \(error)")
            #endif
        }
    }
    
    func getDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: .init(coordinate: from))
        request.destination = MKMapItem(placemark: .init(coordinate: to))
        request.transportType = .automobile
        
        do {
            let directions = try await MKDirections(request: request).calculate()
            if let firstRoute = directions.routes.first {
                #if DEBUG
                print("Distance: \(firstRoute.distance) m")
                print("Estimated duration: \(firstRoute.expectedTravelTime) seconds")
                #endif
                route = firstRoute
            } else {
                #if DEBUG
                print("No route found.")
                #endif
            }
        } catch {
            #if DEBUG
            print("Error calculating directions: \(error)")
            #endif
        }
    }
    
    func geocode(from: CLLocationCoordinate2D, toAddress: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(toAddress) { placemarks, error in
            if let error = error {
                #if DEBUG
                print("Geocoder Error: \(error)")
                #endif
                return
            }
            if let destination = placemarks?.first?.location?.coordinate {
                Task {
                    await self.getDirections(from: from, to: destination)
                }
            } else {
                #if DEBUG
                print("No coordinate found for address: \(toAddress)")
                #endif
            }
        }
    }

    private func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        #if DEBUG
        print("Geocoding address: '\(address)'")
        #endif
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                #if DEBUG
                print("Geocoder Error for '\(address)': \(error.localizedDescription)")
                #endif
                completion(nil)
                return
            }
            
            if let coordinate = placemarks?.first?.location?.coordinate {
                #if DEBUG
                print("Geocoded '\(address)' → \(coordinate.latitude), \(coordinate.longitude)")
                #endif
                completion(coordinate)
            } else {
                #if DEBUG
                print("No coordinate found for address: '\(address)'")
                #endif
                completion(nil)
            }
        }
    }
    
    
    func getDirectionsFromAddresses(fromAddress: String, toAddress: String) async {
        
        let fromTrim = fromAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let toTrim = toAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !toTrim.isEmpty else {
            #if DEBUG
            print("Missing 'to' address")
            #endif
            return
        }
        
        geocodeAddress(toTrim) { destination in
            guard let destination else {
                #if DEBUG
                print("No coordinate found for TO: \(toTrim)")
                #endif
                return
            }
            #if DEBUG
            print("Destination geocoded: \(destination.latitude), \(destination.longitude)")
            #endif
            self.destinationCoordinate = destination

            if fromTrim.isEmpty {
                #if DEBUG
                print("FROM is empty, using user location...")
                #endif
                self.updateUserLocation()
                guard let origin = self.userLocation else {
                    #if DEBUG
                    print("No user location available yet")
                    #endif
                    return
                }
                self.originCoordinate = origin

                Task { @MainActor in
                    await self.getDirections(from: origin, to: destination)
                }

            } else {
                self.geocodeAddress(fromTrim) { origin in
                    guard let origin else {
                        #if DEBUG
                        print("No coordinate found for FROM: \(fromTrim)")
                        #endif
                        return
                    }
                    #if DEBUG
                    print("Origin geocoded: \(origin.latitude), \(origin.longitude)")
                    #endif
                    self.originCoordinate = origin

                    Task { @MainActor in
                        await self.getDirections(from: origin, to: destination)
                    }
                }
            }

        }
    }
    
    func buildResultIfPossible(vehicle: VehicleType, fuel: FuelType, date: Date) {
        guard let route else { return }
        guard !toll.isEmpty else { return }

        tollsOnRoute = tollsNearRoute(route: route, tolls: toll, maxDistanceMeters: 350)
        totalPrice = 0
        hasResult = true
    }
    
    private func tollsNearRoute(route: MKRoute, tolls: [Vegobjekt], maxDistanceMeters: Double) -> [Vegobjekt] {
        let polyline = route.polyline
        let routePoints = samplePolylinePoints(polyline, step: 25)

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
