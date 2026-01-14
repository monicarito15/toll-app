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
    private let manager = CLLocationManager()   // el manager real que pide permisos y ubicación
    private let geocoder = CLGeocoder()         // convierte coordenadas -> dirección (texto)

    // MARK: - Published state (SwiftUI escucha estos cambios)
    @Published var userLocation: CLLocationCoordinate2D?         // coordenadas actuales del usuario
    @Published var authorizationStatus: CLAuthorizationStatus?   // estado de permisos (puede ser nil al inicio)
    @Published var currentAddress: String?                      // dirección actual (texto)

    // MARK: - Init
    override init() {
        super.init()

        // 1) conectamos el delegate para recibir callbacks (didUpdate/didFail/authorization)
        manager.delegate = self

        // 2) precisión (puedes cambiar a .nearestTenMeters si quieres menos batería)
        manager.desiredAccuracy = kCLLocationAccuracyBest

        // guardar el estado de permisos desde el inicio
        // (esto ayuda porque authorizationStatus es opcional y a veces queda nil hasta que cambie)
        self.authorizationStatus = manager.authorizationStatus

        // 3) pedir permisos cuando se crea el LocationManager
        manager.requestWhenInUseAuthorization()

        // 4) empezar a recibir ubicaciones continuamente (streaming)
        // Nota: esto NO es lo mismo que requestLocation() que pide solo una vez
        manager.startUpdatingLocation()
    }

    // MARK: - Delegate: didUpdateLocations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {

                // Guarda coordenadas
                self.userLocation = location.coordinate

                //prints para debug (para saber si realmente llega ubicación)
                print("didUpdateLocations -> \(location.coordinate.latitude), \(location.coordinate.longitude)")

                
                self.reverseGeocode(location: location) // convertir coordenadas para mostar direccion d la locacion
            }
        }
    }

    // MARK: - Public: requestLocation (una sola vez)
    func requestLocation() {

        // lee el status real del manager (más confiable que el @Published opcional)
        let status = manager.authorizationStatus

        // print para ver el estado al tocar el botón
        print("requestLocation() tapped. authStatus = \(status.rawValue)")

        // si todavía no se decidió permiso, primero lo pedimos
        if status == .notDetermined {
            requestAuthorization()
            return
        }

        // si el permiso está denegado/restringido, requestLocation no va a funcionar
        if status == .denied || status == .restricted {
            print("Location permission denied/restricted")
            return
        }

        // Tu línea original (pero ahora solo se ejecuta cuando realmente tiene sentido):
        manager.requestLocation()
    }

    // MARK: - Delegate: didFailWithError
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {

          
            print("Location error: \(error.localizedDescription)")

        }
    }

    // MARK: - Public: requestAuthorization
    func requestAuthorization() {
        // print para saber cuándo se está pidiendo permiso
        print("Requesting WhenInUse authorization...")

        // Tu línea original:
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Delegate: authorization changed
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {

            // Tu asignación original:
            self.authorizationStatus = manager.authorizationStatus

            // print para confirmar el cambio de permisos
            print("Authorization changed -> \(manager.authorizationStatus.rawValue)")
        }
    }

    // MARK: - reverseGeocoding - convertir coordenadas a direccion
    func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemark, error in

            //si falla el reverse geocode, ahora lo vas a ver en consola
            if let error = error {
                print("ReverseGeocode error: \(error.localizedDescription)")
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

                    // print para confirmar que sí se setea currentAddress
                    print("currentAddress set -> \(self.currentAddress ?? "nil")")
                }

            } else {
                //si no hay placemark, también lo verás
                print("ReverseGeocode: no placemark found")
            }
        }
    }
}

