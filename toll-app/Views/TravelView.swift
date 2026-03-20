
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
    @State private var hasAutopass: Bool = false
 
    
    var body: some View {
        MapView(
            from: from,
            to: to,
            vehicleType: vehicleType,
            fuelType: fuelType,
            dateTime: dateTime,
            hasAutopass: hasAutopass,
            mapVM: vm
        )
        
        .sheet(isPresented: $showSheet) {
            VStack {
                CalculatorView(
                    mapVM: vm,
                    currentDetent: $currentDetent,
                    onCalculate:{
                    newFrom, newTo, newVehicle, newFuel, newDate, newAutopass  in
                    from = newFrom
                    to = newTo
                    vehicleType = newVehicle
                    fuelType = newFuel
                    dateTime = newDate
                    hasAutopass = newAutopass
                    
                    Task {@MainActor in
                        await vm.getDirectionsFromAddresses(fromAddress: from, toAddress: to)
                    }
                
                }
            )
        }
            .presentationDetents([.medium, .large], selection: $currentDetent)
            .onAppear {
                currentDetent = .medium // Asegura que el sheet siempre se abra medium
            }
        }
    }
        
}

