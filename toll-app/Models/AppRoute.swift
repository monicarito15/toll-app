import MapKit

// Reemplaza MKRoute para soportar rutas de OSRM además de MapKit
struct AppRoute: Equatable {
    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        lhs.polyline === rhs.polyline
    }
    let polyline: MKPolyline
    let distance: Double        // metros
    let expectedTravelTime: TimeInterval  // segundos
    let name: String
    let hasFerry: Bool
}
