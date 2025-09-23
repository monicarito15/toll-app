import SwiftUI
import MapKit

struct SearchView: View {
    
    
    var body: some View {
        MapView(
            from: "Start Location",
                        to: "End Location",
                        vehicleType: "Car",
                        fuelType: "Gasoline",
                        dateTime: Date()
        )
    }
}

