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
    
    
    /*@State private var camaraPosition: MapCameraPosition = .region(
     MKCoordinateRegion(
     center: CLLocationCoordinate2D(latitude: 60.397076, longitude: 5.324383),
     latitudinalMeters: 1000,
     longitudinalMeters: 100
     )
     )*/
    let camaraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 60.418006092804866, longitude: 5.312973779070781), latitudinalMeters: 1500, longitudinalMeters: 1500))
    
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        VStack {
            ZStack {
                Map(initialPosition: camaraPosition) {
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
                    UserAnnotation()
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
            Button("Calcular ruta entre dos tolls") {
                if toll.count >= 2,
                   let coord1 = toll[0].lokasjon.coordinates,
                   let coord2 = toll[1].lokasjon.coordinates {
                    // For test: draw route between first two tolls
                    getDirections(from: coord1, to: coord2)
                } else if let firstToll = toll.first?.lokasjon.coordinates {
                    // For test: draw route from user location to first toll
                    getDirections(to: firstToll)
                }
            }
            .padding()
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
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
    
    func getUserLocation() async -> CLLocationCoordinate2D? {
        let updates = CLLocationUpdate.liveUpdates() // Get live location updates
        
        do {
            let update = try await updates.first { $0.location?.coordinate != nil}
            return update?.location?.coordinate
            
        } catch {
            print("Error getting user location: \(error)")
        }
        return nil
    }
    
    // Draw route from user location to destination
    func getDirections(to destination: CLLocationCoordinate2D)  {
        Task {
            guard let userLocation = await getUserLocation() else { return }
            print("User location: \(userLocation.latitude), \(userLocation.longitude)")
            
                let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: userLocation))
            request.destination = MKMapItem(placemark: .init(coordinate: destination))
            
            do {
                let directions = try await MKDirections(request: request).calculate()
                route = directions.routes.first // Store the first route
            } catch {
                print("Error calculating directions: \(error)")
            }
        }
    }
    
    // Draw route between two coordinates
    func getDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        Task {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: from))
            request.destination = MKMapItem(placemark: .init(coordinate: to))
            do {
                let directions = try await MKDirections(request: request).calculate()
                route = directions.routes.first
            } catch {
                print("Error calculating directions: \(error)")
            }
        }
    }
}
