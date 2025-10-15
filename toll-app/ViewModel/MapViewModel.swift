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
    
    private let locationManager = LocationManager()
    
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
    func getDirectionsToAddress(from: CLLocationCoordinate2D, toAddress: String) {
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
}

