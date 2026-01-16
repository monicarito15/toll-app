
// Este es el parent de calculatorView
import SwiftUI
import MapKit

struct TravelView: View {
    
    @Binding var showSheet: Bool
    @Binding var currentDetent : PresentationDetent
    
    @StateObject private var vm = MapViewModel()
    
    @State private var from = ""
    @State private var to = ""
    @State private var vehicleType: VehicleType = .car
    @State private var fuelType: FuelType = .gas
    @State private var dateTime: Date = Date()
    
    var body: some View {
        MapView(
            from: from,
            to: to,
            vehicleType: vehicleType,
            fuelType: fuelType,
            dateTime: dateTime,
            mapVM: vm
)
        
        .sheet(isPresented: $showSheet) {
            VStack {
                CalculatorView (currentDetent: $currentDetent) {
                    newFrom, newTo, newVehicle, newFuel, newDate in
                    from = newFrom
                    to = newTo
                    vehicleType = newVehicle
                    fuelType = newFuel
                    dateTime = newDate
                    
                    Task {@MainActor in
                        await vm.getDirectionsFromAddresses(fromAddress: from, toAddress: to)}
                }
            }
            .presentationDetents([.medium, .large], selection: $currentDetent)
            .onAppear {
                currentDetent = .medium // Asegura que el sheet siempre se abra medium
            }
        }
    }
        
}

