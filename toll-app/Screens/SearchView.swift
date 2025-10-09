import SwiftUI
import MapKit

struct SearchView: View {
    
    @Binding var showSheet: Bool
    @Binding var currentDetent : PresentationDetent
    
    var body: some View {
        MapView(
            from: "Start Location",
                        to: "End Location",
                        vehicleType: "Car",
                        fuelType: "Gasoline",
                        dateTime: Date()
        )
        
        .sheet(isPresented: $showSheet) {
            VStack {
                CalculatorView (currentDetent: $currentDetent)
            }
            .presentationDetents([.medium, .large], selection: $currentDetent)
            .onAppear {
                currentDetent = .medium // Asegura que el sheet siempre se abra medium
            }
        }
    }
        
}

