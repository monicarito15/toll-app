
// Este es el parent de calculatorView
import SwiftUI
import MapKit
import SwiftData

struct TravelView: View {

    @Binding var showSheet: Bool
    @Binding var currentDetent : PresentationDetent

    @Binding var selectedHistoryItem: SearchHistoryItem?

    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = MapViewModel()
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showPaywall = false
    
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
                        guard purchaseManager.canSearch else {
                            showPaywall = true
                            return
                        }
                        purchaseManager.recordSearch()
                        vm.resetResult()
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
            .presentationDetents([.height(520), .large], selection: $currentDetent)
            .presentationDragIndicator(.visible)
            .onAppear {
                currentDetent = .height(520)
            }
        }
      
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
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
        .onChange(of: vm.tollsOnRoute) { _, tolls in
            guard vm.hasResult else { return }
            let existing = (try? modelContext.fetch(FetchDescriptor<SearchHistoryItem>(
                sortBy: [SortDescriptor(\.searchDate, order: .reverse)]
            ))) ?? []
            guard let latest = existing.first else { return }
            latest.tollCount = tolls.count
            try? modelContext.save()
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

