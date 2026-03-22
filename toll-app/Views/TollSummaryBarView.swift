import SwiftUI
import MapKit

struct TollSummaryBar: View {
    let tollCount: Int
    let total: Double
    let isEstimated: Bool
    let vehicleType: VehicleType
    let fuelType: FuelType
    let hasAutopass: Bool
    let originCoordinate: CLLocationCoordinate2D?
    let destinationCoordinate: CLLocationCoordinate2D?
    let fromAddress: String
    let toAddress: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Línea superior: Total de peajes y precio
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total tolls: \(tollCount)")
                            .font(.headline)

                        HStack(spacing: 4) {
                            Text("Total price: \(Int(total)) kr")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if isEstimated {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text("est.")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Details")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.up")
                            .font(.caption)
                    }
                }
                
                // Línea inferior: Detalles del vehículo
                HStack(spacing: 12) {
                    // Tipo de vehículo
                    HStack(spacing: 4) {
                        Image(systemName: vehicleType == .car ? "car.fill" : "bicycle")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(vehicleType.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 12)
                    
                    // Tipo de combustible
                    HStack(spacing: 4) {
                        Image(systemName: fuelType == .electric ? "bolt.fill" : "fuelpump.fill")
                            .font(.caption)
                            .foregroundStyle(fuelType == .electric ? .green : .orange)
                        Text(fuelType.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 12)
                    
                    // Autopass
                    HStack(spacing: 4) {
                        Image(systemName: hasAutopass ? "checkmark.shield.fill" : "shield.slash.fill")
                            .font(.caption)
                            .foregroundStyle(hasAutopass ? .green : .gray)
                        Text(hasAutopass ? "Autopass" : "No Autopass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 500) // Limitar el ancho máximo
        .padding(.horizontal, 60) // Más padding horizontal para alejar de los bordes
        .padding(.top, 80) // Más padding para bajar más la barra
    }
}

// MARK: - Floating Navigation Button

struct NavigationFloatingButton: View {
    let originCoordinate: CLLocationCoordinate2D?
    let destinationCoordinate: CLLocationCoordinate2D?
    let fromAddress: String
    let toAddress: String
    
    @State private var showNavigationOptions = false
    
    var body: some View {
        Button(action: {
            showNavigationOptions = true
        }) {
            Image(systemName: "location.fill.viewfinder")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .confirmationDialog("Choose Navigation App", isPresented: $showNavigationOptions) {
            Button("Apple Maps") {
                openInAppleMaps()
            }
            
            Button("Google Maps") {
                openInGoogleMaps()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select the app to navigate this route")
        }
    }
    
    // MARK: - Navigation Methods
    
    private func openInAppleMaps() {
        guard let origin = originCoordinate, let destination = destinationCoordinate else {
            print(" Missing coordinates for navigation")
            return
        }
        
        let originPlacemark = MKPlacemark(coordinate: origin)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let originItem = MKMapItem(placemark: originPlacemark)
        originItem.name = fromAddress.isEmpty ? "Origin" : fromAddress
        
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        destinationItem.name = toAddress.isEmpty ? "Destination" : toAddress
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        MKMapItem.openMaps(with: [originItem, destinationItem], launchOptions: launchOptions)
        print("Opening route in Apple Maps")
    }
    
    private func openInGoogleMaps() {
        guard let origin = originCoordinate, let destination = destinationCoordinate else {
            print("Missing coordinates for navigation")
            return
        }
        
        // Formato: comgooglemaps://?saddr=LAT,LON&daddr=LAT,LON&directionsmode=driving
        let urlString = "comgooglemaps://?saddr=\(origin.latitude),\(origin.longitude)&daddr=\(destination.latitude),\(destination.longitude)&directionsmode=driving"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            // Google Maps está instalado
            UIApplication.shared.open(url)
            print("Opening route in Google Maps")
        } else {
            // Google Maps no está instalado, abrir en el navegador
            let webUrlString = "https://www.google.com/maps/dir/?api=1&origin=\(origin.latitude),\(origin.longitude)&destination=\(destination.latitude),\(destination.longitude)&travelmode=driving"
            
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
                print("Opening route in Google Maps web")
            }
        }
    }
}

// MARK: - Previews

#Preview("TollSummaryBar") {
    VStack {
        Spacer()
        TollSummaryBar(
            tollCount: 8,
            total: 217,
            isEstimated: false,
            vehicleType: .car,
            fuelType: .electric,
            hasAutopass: true,
            originCoordinate: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
            destinationCoordinate: CLLocationCoordinate2D(latitude: 60.3913, longitude: 5.3221),
            fromAddress: "Oslo",
            toAddress: "Bergen"
        ) {
            print("Tapped details")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}

#Preview("Floating Navigation Button") {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationFloatingButton(
                    originCoordinate: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
                    destinationCoordinate: CLLocationCoordinate2D(latitude: 60.3913, longitude: 5.3221),
                    fromAddress: "Oslo",
                    toAddress: "Bergen"
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
}


