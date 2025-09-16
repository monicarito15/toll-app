import SwiftUI
import MapKit
import CoreLocation
import ArcGIS


struct MapView: View {
    
    @State private var toll: [Vegobjekt] = [] // Store fetched toll objects
    
    
    /*@State private var camaraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 60.397076, longitude: 5.324383),
            latitudinalMeters: 1000,
            longitudinalMeters: 100
        )
    )*/
    let camaraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 60.418006092804866, longitude: 5.312973779070781), latitudinalMeters: 1000, longitudinalMeters: 1000))
    
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        Map(initialPosition: camaraPosition) {
            ForEach(toll) { vegobjekt in
                if let coordinate = vegobjekt.lokasjon.coordinates
                {
                    Marker("Toll #\(vegobjekt.id),", systemImage: "car", coordinate: coordinate)
                }
            }
            UserAnnotation()
        }
        .tint(.green)
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
