/*import SwiftUI
import MapKit

struct TollMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var tollService = TollSearchService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        Group {
            if let userLocation = locationManager.userLocation {
                Map(position: $cameraPosition) {
                    // Anotación del usuario (opcional)
                    UserAnnotation()
                    
                    // Anotaciones de peajes
                    ForEach(tollService.tollItems, id: \.self) { item in
                        if let coord = item.placemark.location?.coordinate {
                            Annotation(item.name ?? "Toll", coordinate: coord) {
                                ZStack {
                                    Circle().fill(.blue).frame(width: 28, height: 28)
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    locationManager.requestLocation()
                    if let userLocation = locationManager.userLocation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: userLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        ))
                        tollService.searchTolls(near: userLocation)
                    }
                }
                .onReceive(locationManager.$userLocation) { newLocation in
                    guard let newLocation else { return }
                    cameraPosition = .region(MKCoordinateRegion(
                        center: newLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    ))
                    tollService.searchTolls(near: newLocation)
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Obteniendo ubicación…")
                }
            }
        }
    }
} */
