
//  ViewModel: contiene la lógica de ubicación, rutas y tolls desde NVDB, hasResult(muestra la barra despues del calculo).


import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    
    
    @Published var routes: [MKRoute] = []
    @Published var selectedRouteIndex: Int = 0
    @Published var toll: [Vegobjekt] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var originCoordinate: CLLocationCoordinate2D?
    @Published var destinationCoordinate: CLLocationCoordinate2D?

    // Para la barrita + sheet
    @Published var hasResult: Bool = false
    @Published var totalPrice: Double = 0
    @Published var tollsOnRoute: [Vegobjekt] = []

    var route: MKRoute? {
        guard selectedRouteIndex < routes.count else { return nil }
        return routes[selectedRouteIndex]
    }
    

    
    private let locationManager = LocationManager()
    
    func resetResult() {
        hasResult = false
        totalPrice = 0
        tollsOnRoute = []
        routes = []
        originCoordinate = nil
        destinationCoordinate = nil
    }
    
    func selectRoute(index: Int) {
        guard index < routes.count else { return }
        selectedRouteIndex = index  // UI responds instantly (route color changes)
        guard let route else { return }
        let capturedRoute = route
        let capturedTolls = toll
        Task {
            await Task.yield()  // let the UI redraw the new selected route first
            tollsOnRoute = tollsNearRoute(route: capturedRoute, tolls: capturedTolls, maxDistanceMeters: 150)
        }
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
        request.requestsAlternateRoutes = true

        do {
            let result = try await MKDirections(request: request).calculate()
            guard !result.routes.isEmpty else {
                #if DEBUG
                print("No route found.")
                #endif
                return
            }
            selectedRouteIndex = 0
            routes = result.routes
            #if DEBUG
            print("Routes found: \(routes.count)")
            for (i, r) in routes.enumerated() {
                print("  Route \(i): \(Int(r.distance/1000)) km — \(r.name)")
            }
            #endif
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
    
    
    func getDirectionsFromAddresses(
        fromAddress: String,
        toAddress: String,
        fromCoordinate: CLLocationCoordinate2D? = nil,
        toCoordinate: CLLocationCoordinate2D? = nil
    ) async {
        
        let fromTrim = fromAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let toTrim = toAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !toTrim.isEmpty || toCoordinate != nil else {
            #if DEBUG
            print("Missing 'to' address")
            #endif
            return
        }
        
        // Resolve destination coordinate
        let destination: CLLocationCoordinate2D
        if let toCoordinate {
            destination = toCoordinate
        } else {
            guard let geocoded = await geocodeAddressAsync(toTrim) else {
                #if DEBUG
                print("No coordinate found for TO: \(toTrim)")
                #endif
                return
            }
            destination = geocoded
        }
        
        #if DEBUG
        print("Destination: \(destination.latitude), \(destination.longitude)")
        #endif
        destinationCoordinate = destination
        
        // Resolve origin coordinate
        let origin: CLLocationCoordinate2D
        if let fromCoordinate {
            origin = fromCoordinate
        } else if fromTrim.isEmpty {
            #if DEBUG
            print("FROM is empty, using user location...")
            #endif
            updateUserLocation()
            guard let userLoc = userLocation else {
                #if DEBUG
                print("No user location available yet")
                #endif
                return
            }
            origin = userLoc
        } else {
            guard let geocoded = await geocodeAddressAsync(fromTrim) else {
                #if DEBUG
                print("No coordinate found for FROM: \(fromTrim)")
                #endif
                return
            }
            origin = geocoded
        }
        
        #if DEBUG
        print("Origin: \(origin.latitude), \(origin.longitude)")
        #endif
        originCoordinate = origin
        
        await getDirections(from: origin, to: destination)
    }
    
    private func geocodeAddressAsync(_ address: String) async -> CLLocationCoordinate2D? {
        #if DEBUG
        print("Geocoding address: '\(address)'")
        #endif
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location?.coordinate
        } catch {
            #if DEBUG
            print("Geocoder Error for '\(address)': \(error.localizedDescription)")
            #endif
            return nil
        }
    }
    
    func buildResultIfPossible(vehicle: VehicleType, fuel: FuelType, date: Date) {
        guard let route else { return }
        guard !toll.isEmpty else { return }

        tollsOnRoute = tollsNearRoute(route: route, tolls: toll, maxDistanceMeters: 150) // Reduci la distancia para tener puntos mas cercanos
        totalPrice = 0
        hasResult = true
    }
    
    private func tollsNearRoute(route: MKRoute, tolls: [Vegobjekt], maxDistanceMeters: Double) -> [Vegobjekt] {
        let polyline = route.polyline
        let routePoints = samplePolylinePoints(polyline, step: 10)

        // Find tolls near route and track which route point index they're closest to
        var tollsWithPosition: [(toll: Vegobjekt, routeIndex: Int)] = []
        
        for toll in tolls {
            guard let c = toll.lokasjon?.coordinates else { continue }
            let tollLoc = CLLocation(latitude: c.latitude, longitude: c.longitude)
            
            var closestIndex = -1
            var closestDistance = Double.greatestFiniteMagnitude
            
            for (index, p) in routePoints.enumerated() {
                let d = tollLoc.distance(from: CLLocation(latitude: p.latitude, longitude: p.longitude))
                if d < closestDistance {
                    closestDistance = d
                    closestIndex = index
                }
            }
            
            if closestDistance <= maxDistanceMeters {
                tollsWithPosition.append((toll: toll, routeIndex: closestIndex))
            }
        }
        
        // Sort by position along the route
        return tollsWithPosition
            .sorted { $0.routeIndex < $1.routeIndex }
            .map { $0.toll }
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
