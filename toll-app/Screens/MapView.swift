import SwiftUI
import MapKit
import CoreLocation
import ArcGIS


struct MapView: View {
    
    let from: String
    let to: String
    let vehicleType: String
    let fuelType: String
    let dateTime: Date
    
    

    @State private var route: MKRoute? // Store the calculated route
    @State private var toll: [Vegobjekt] = [] // Store fetched toll objects
    
    @StateObject private var locationManager = LocationManager()

    let camaraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 60.418006092804866, longitude: 5.312973779070781), latitudinalMeters: 1500, longitudinalMeters: 1500))
    
    
    //let locationManager = CLLocationManager()
    
    var body: some View {
        VStack {
            ZStack {
                Map(initialPosition: camaraPosition) {
                    
                    // user location
                    if let userLocation = locationManager.userLocation {
                        // Center map on user location
                        Marker("My location", coordinate: userLocation)
                    }
                        
                    //Marker("Destination", coordinate: CLLocationCoordinate2D(latitude: 60.418006092804866, longitude: 5.312973779070781))
                    
                    
                    // tolls
                    ForEach(toll) { vegobjekt in
                        if let coordinate = vegobjekt.lokasjon.coordinates {
                            let tollName = vegobjekt.egenskaper.first(where: { $0.navn == "Navn bomstasjon" })?.verdi
                                ?? vegobjekt.egenskaper.first(where: { $0.navn == "Navn bompengeanlegg (fra CS)" })?.verdi
                                ?? "Unknown"
                            let labelText = "Toll #\(vegobjekt.id) - \(tollName)"
                            Annotation(labelText, coordinate: coordinate) {
                                Label(labelText, systemImage: "car")
                                    .labelStyle(.iconOnly)
                                    .font(.title)
                                    .shadow(radius: 5)
                                    .foregroundColor(.blue)
                                
                            }
                        }
                    }
                   // UserAnnotation()
                    if let route = route {
                        MapPolyline(route)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .tint(.red)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                    MapScaleView()
                }
                .mapStyle(.standard(elevation: .realistic))
            }
            Button("Calcular ruta") {
                if let userLocation = locationManager.userLocation,
                   let firstToll = toll.first?.lokasjon.coordinates {
                    print("Calculate route from \(userLocation) to \(firstToll)")
                    getDirections(from: userLocation, to: firstToll)
                } else {
                    print("Not found user location and toll")
                }
            }
            .padding()
        }
        .onAppear {
            if let userLocation = locationManager.userLocation {
                getDirectionsToAddress(from: userLocation, toAddress: to )
            }
            
        }
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
    
    // Function for draw route between two coordinates
    func getDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        Task {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: from))
            request.destination = MKMapItem(placemark: .init(coordinate: to))
            request.transportType = .automobile
            do {
                let directions = try await MKDirections(request: request).calculate()
                if let firstRoute = directions.routes.first {
                    print("Route distance: \(firstRoute.distance) meters")
                    print("Route estimated duration: \(firstRoute.expectedTravelTime) seconds")
                    route = firstRoute
                } else {
                    print("Not found a route")
                }
            } catch {
                print("Error calculating directions: \(error)")
            }
        }
    }
    
    // fuction to get direction TO address - Geocoding = de direccion a coordenadas
    func getDirectionsToAddress (from: CLLocationCoordinate2D, toAddress: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(toAddress) { placemaks, error in
            if let error = error {
                print("Geocoder error: \(error)")
                return
            }
            if let destination = placemaks?.first?.location?.coordinate {
                getDirections(from: from, to: destination)
            } else {
                print("No destination found for \(toAddress)")
            }
            
        }
    }
}
