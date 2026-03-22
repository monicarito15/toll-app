
// Este es el parent de calculatorView
import SwiftUI
import MapKit

struct TravelView: View {
    
    @Binding var showSheet: Bool
    @Binding var currentDetent : PresentationDetent
    @Binding var searchHistory : [SearchHistoryItem]
    @Binding var selectedHistoryItem: SearchHistoryItem?
    
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
                        
                        // Guardar la búsqueda en el historial
                        let newSearch = SearchHistoryItem(
                            fromAddress: newFrom,
                            toAddress: newTo,
                            vehicleType: newVehicle,
                            fuelType: newFuel,
                            dateTime: newDate,
                            hasAutopass: newAutopass,
                            totalPrice: vm.totalPrice,
                            tollCount: vm.tollsOnRoute.count
                        )
                        
                        // Agregar al inicio del array (más reciente primero)
                        searchHistory.insert(newSearch, at: 0)
                        
                        // Limitar a los últimos 30 días o 50 búsquedas
                        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
                        searchHistory = searchHistory
                            .filter { $0.searchDate > thirtyDaysAgo }
                            .prefix(50)
                            .map { $0 }
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

