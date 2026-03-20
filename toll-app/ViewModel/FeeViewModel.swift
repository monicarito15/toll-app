
// Este ViewModel contiene: key - leer SwiftData (24h)- si no hay (llamar API → guardar) - exponer totalPrice, tollCharges, lastFeeUpdate

import SwiftUI
import SwiftData
import CoreLocation

@MainActor
final class FeeViewModel: ObservableObject {
    
    @Published var tollCharges: [TollCharge] = []
    @Published var totalPrice: Double = 0
    @Published var lastFeeUpdate: Date?
    @Published var hasAutoPassAgreement: Bool = false
    @Published var isLoadingPrices: Bool = false
    
    //Funcion para crear el KEY
    private func roundTo15Min(_ date: Date) -> Date {
        let t = date.timeIntervalSince1970
        return Date(timeIntervalSince1970: floor(t / 900) * 900)
    }

    func feeCalculationKey(
        from: String,
        to: String,
        vehicle: VehicleType,
        fuel: FuelType,
        date: Date
    ) -> String {
        let rounded = roundTo15Min(date)
        return "\(from)|\(to)|\(vehicle)|\(fuel)|\(rounded.timeIntervalSince1970)|autopass:\(hasAutoPassAgreement)"
    }
    
    
    // Punto de entrada: usa cache 24h, si no existe llama a la API REAL de Bompenger
    func loadOrCalculateFees(
        tollsOnRoute: [Vegobjekt],
        from: String,
        to: String,
        vehicle: VehicleType,
        fuel: FuelType,
        date: Date,
        modelContext: ModelContext,
        storage: FeeStorageViewModel,
        originCoordinate: CLLocationCoordinate2D?,
        destinationCoordinate: CLLocationCoordinate2D?
    ) {
        guard !tollsOnRoute.isEmpty else {
            totalPrice = 0
            tollCharges = []
            lastFeeUpdate = nil
            return
        }
        
        let key = feeCalculationKey(from: from, to: to, vehicle: vehicle, fuel: fuel, date: date)
        
        // 1. Verificar cache primero
        storage.load(using: modelContext, key: key)
        
        if let saved = storage.calculation, storage.isValid(saved) {
            totalPrice = saved.total
            tollCharges = storage.decodeCharges(saved)
            lastFeeUpdate = saved.createdAt
            print("FeeVM: Using cached prices: \(totalPrice) NOK")
            return
           
        }
        
        // 2. No hay cache válido entonces Llamar a la API del boompenger
        guard let origin = originCoordinate, let destination = destinationCoordinate else {
            print("FeeVM: Warning - Missing coordinates for API call, using local calculation")
            useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
            return
        }
        
        // 3. Llamar a TU BompengerService (API)
        isLoadingPrices = true
        
        Task { @MainActor in
            do {
                print("FeeVM: Calling Bompenger API.")
                
                // Preparar request con TUS parámetros
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let dateString = dateFormatter.string(from: date)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HHmm"
                let timeString = timeFormatter.string(from: date)
                
                let waypointBody = WaypointRequest(
                    fra: Waypointlist(latitude: origin.latitude, longitude: origin.longitude, time: nil),
                    til: Waypointlist(latitude: destination.latitude, longitude: destination.longitude, time: nil),
                    dato_yyyymmdd: dateString,
                    tidspunkt_hhmm: timeString,
                    bilsize: vehicle == .car ? 1 : 2,
                    litenbiltype: fuel == .electric ? 2 : 1,
                    retur: 0,
                    tidsreferanser: 1
                )
                
                // Llamar a TU servicio
                let response = try await BompengerService.shared.getFeesByWaypoint(body: waypointBody)
                
                // Obtener el precio correcto según autopass
                if let apiTotalPrice = response.getPrice(hasAutopass: hasAutoPassAgreement) {
                    let pricePerToll = apiTotalPrice / Double(tollsOnRoute.count)
                    
                    let charges = tollsOnRoute.map { v in
                        let name = v.egenskaper.first(where: { $0.navn == "Navn bomstasjon"})?.verdi ?? "Ukjent"
                        return TollCharge(id: "\(v.id)", toll: name, price: pricePerToll)
                    }
                    
                    totalPrice = apiTotalPrice
                    tollCharges = charges
                    lastFeeUpdate = Date()
                    isLoadingPrices = false
                    
                    print("FeeVM: Success, Got prices from API: \(apiTotalPrice) NOK (autopass: \(hasAutoPassAgreement))")
                    
                    // Log ambos precios para debugging
                    let prices = response.getPrices()
                    print("FeeVM: Without autopass: \(prices.withoutAutopass ?? 0) NOK")
                    print("FeeVM: With autopass: \(prices.withAutopass ?? 0) NOK")
                    
                    // Guardar en cache por 24 horas
                    storage.save(using: modelContext, key: key, total: apiTotalPrice, charges: charges, ttlHours: 24)
                    
                } else {
                    print("FeeVM: API returned no price, using local calculation")
                    isLoadingPrices = false
                    useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
                }
                
            } catch {
                print("FeeVM: Error - API call failed: \(error.localizedDescription), using local calculation")
                isLoadingPrices = false
                useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
            }
        }
    }
    
    // MARK: - Fallback Local
    
    // Usa cálculo local si la API no está disponible
    private func useFallbackCalculation(
        tollsOnRoute: [Vegobjekt],
        vehicle: VehicleType,
        fuel: FuelType,
        storage: FeeStorageViewModel,
        modelContext: ModelContext,
        key: String
    ) {
        let pricePerToll = TollPriceCalculator.calculateTollPrice(
            vehicleType: vehicle,
            fuelType: fuel,
            hasAutopass: hasAutoPassAgreement
        )
        
        let charges = tollsOnRoute.map { v in
            let name = v.egenskaper.first(where: { $0.navn == "Navn bomstasjon"})?.verdi ?? "Ukjent"
            return TollCharge(id: "\(v.id)", toll: name, price: pricePerToll)
        }
        let total = charges.reduce(0) { $0 + $1.price }
        
        totalPrice = total
        tollCharges = charges
        lastFeeUpdate = Date()
        
        print("FeeVM: Using local calculation (estimated): \(total) NOK")
        
        // Guardar en cache
        storage.save(using: modelContext, key: key, total: total, charges: charges, ttlHours: 24)
    }
}


