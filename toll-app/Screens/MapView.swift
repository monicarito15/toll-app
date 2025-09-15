import SwiftUI
import MapKit
import CoreLocation


struct MapView: View {
    
    @State private var toll: [Vegobjekt] = [] // Store fetched toll objects
    
    let camapaPosition: MapCameraPosition = .region(.init(center: .init(latitude: 60.391262, longitude: 5.322054), latitudinalMeters: 1300, longitudinalMeters: 1300))
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        Map(initialPosition: camapaPosition) {
            ForEach(toll) { vegobjekt in
                if let coordinate = vegobjekt.lokasjon.coordinates {
                    Marker("Toll #\(vegobjekt.id)", systemImage: "car", coordinate: coordinate)
                }
            }
            UserAnnotation()
        }
        .tint(.pink)
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic))
        .task {
            do {
                toll = try await TollService.shared.getTolls()
            } catch GHError.invalidURL {
                print("Invalid URL")
            } catch GHError.invalidResponse {
                print("Invalid Response")
            } catch GHError.invalidData {
                print("Invalid Data")
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }
    
    }

extension CLLocationCoordinate2D {
    static let tollLocation = CLLocationCoordinate2D(latitude: 63.40504016561072, longitude: 10.425258382949021)
}
