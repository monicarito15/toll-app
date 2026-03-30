
// Este es el parent de calculatorView
import SwiftUI
import MapKit

struct TravelView: View {
    
    @Binding var showSheet: Bool
    @Binding var currentDetent : PresentationDetent
    
    @Binding var selectedHistoryItem: SearchHistoryItem?
    
    @StateObject private var vm = MapViewModel()
    
    @State private var from = ""
    @State private var to = ""
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    @State private var vehicleType: VehicleType = .car
    @State private var fuelType: FuelType = .gas
    @State private var dateTime: Date = Date()
    @State private var hasAutopass: Bool = true
    
 
    
    var body: some View {
        MapView(
            from: from,
            to: to,
            fromCoordinate: fromCoordinate,
            toCoordinate: toCoordinate,
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
                    from: $from,
                    to: $to,
                    fromCoordinate: $fromCoordinate,
                    toCoordinate: $toCoordinate,
                    autopassOn: $hasAutopass,
                    currentDetent: $currentDetent,
                    selectedFuelType: $fuelType,
                    selectedVehicleType: $vehicleType,
                    selectedDateTime: $dateTime,
                    onCalculate: {
                        Task { @MainActor in
                            await vm.getDirectionsFromAddresses(
                                fromAddress: from,
                                toAddress: to,
                                fromCoordinate: fromCoordinate,
                                toCoordinate: toCoordinate
                            )
                        }
                    }
                )
        }
            .presentationDetents([.medium, .large], selection: $currentDetent)
            .onAppear {
                currentDetent = .medium // Asegura que el sheet siempre se abra medium
            }
        }
        .onChange(of: selectedHistoryItem) { oldValue, newValue in
            // Cuando se selecciona un item del historial, rellenar los campos
            if let historyItem = newValue {
                from = historyItem.fromAddress
                to = historyItem.toAddress
                vehicleType = historyItem.vehicleTypeEnum
                fuelType = historyItem.fuelTypeEnum
                dateTime = historyItem.dateTime
                hasAutopass = historyItem.hasAutopass
                
                // Abrir el sheet con los datos precargados
                showSheet = true
                
                // Limpiar la selección
                selectedHistoryItem = nil
            }
        }
    }
        
}

