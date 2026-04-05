
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
    
    @AppStorage("defaultVehicle") private var defaultVehicle: String = VehicleType.car.rawValue
    @AppStorage("defaultFuel") private var defaultFuel: String = FuelType.gas.rawValue
    @AppStorage("defaultAutopass") private var defaultAutopass: Bool = false

    @State private var vehicleType: VehicleType = VehicleType(rawValue: UserDefaults.standard.string(forKey: "defaultVehicle") ?? "") ?? .car
    @State private var fuelType: FuelType = FuelType(rawValue: UserDefaults.standard.string(forKey: "defaultFuel") ?? "") ?? .gas
    @State private var dateTime: Date = Date()
    @State private var hasAutopass: Bool = UserDefaults.standard.bool(forKey: "defaultAutopass")
    
 
    
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
        } // estos onchange muestran el userDefault - sin transcribir la ruta activa
        .onChange(of: defaultVehicle) { _, newValue in
            if from.isEmpty && to.isEmpty {
                vehicleType = VehicleType(rawValue: newValue) ?? .car
            }
        }
        .onChange(of: defaultFuel) { _, newValue in
            if from.isEmpty && to.isEmpty {
                fuelType = FuelType(rawValue: newValue) ?? .gas
            }
        }
        .onChange(of: defaultAutopass) { _, newValue in
            if from.isEmpty && to.isEmpty {
                hasAutopass = newValue
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

