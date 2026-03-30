//  Floating Navigation Button

import SwiftUI
import CoreLocation
import MapKit

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
    
    // Navigation Methods
    
    private func openInAppleMaps() {
        guard let origin = originCoordinate, let destination = destinationCoordinate else {
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
    }
    
    private func openInGoogleMaps() {
        guard let origin = originCoordinate, let destination = destinationCoordinate else {
            return
        }
        
        // Formato: comgooglemaps://?saddr=LAT,LON&daddr=LAT,LON&directionsmode=driving
        let urlString = "comgooglemaps://?saddr=\(origin.latitude),\(origin.longitude)&daddr=\(destination.latitude),\(destination.longitude)&directionsmode=driving"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            // Google Maps está instalado
            UIApplication.shared.open(url)
        } else {
            // Google Maps no está instalado, abrir en el navegador
            let webUrlString = "https://www.google.com/maps/dir/?api=1&origin=\(origin.latitude),\(origin.longitude)&destination=\(destination.latitude),\(destination.longitude)&travelmode=driving"
            
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
            }
        }
    }
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
