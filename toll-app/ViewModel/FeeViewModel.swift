
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
    @Published var isEstimatedPrice: Bool = false // Indica si el precio es estimado (fallback) o real (API)
    
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
            isEstimatedPrice = false // Asumimos que caché = precio real
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
                // Preparar request con TUS parámetros
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let dateString = dateFormatter.string(from: date)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HHmm"
                let timeString = timeFormatter.string(from: date)
                
                print("FeeVM: Calling Bompenger API")
                print("   From: \(origin.latitude), \(origin.longitude)")
                print("   To: \(destination.latitude), \(destination.longitude)")
                print("   Date: \(dateString), Time: \(timeString)")
                print("   Vehicle: \(vehicle.rawValue)")
                print("   Fuel: \(fuel.rawValue)")
                print("   Autopass: \(hasAutoPassAgreement ? "YES" : "NO")")
                
                // Mapeo correcto según API de Bompenger:
                // bilsize: 1 = Small vehicle (car/motorcycle), 2 = Large vehicle (truck/van)
                // litenbiltype: 1 = Fossil fuel (gas/diesel), 2 = Electric
                //
                // ⚠️ IMPORTANTE: Si los precios salen invertidos, podría ser que el API
                // tenga la lógica al revés. En ese caso, cambia USE_INVERTED_LOGIC a true.
                let USE_INVERTED_LOGIC = false
                
                let vehicleSize = 1 // Always 1 for car/motorcycle
                
                let fuelTypeCode: Int
                if USE_INVERTED_LOGIC {
                    // Lógica invertida (el API tiene los valores al revés)
                    switch fuel {
                    case .gas:
                        fuelTypeCode = 2 // Gas → enviar código 2
                        print("   Detected GAS -> API code: 2 (INVERTED)")
                    case .electric:
                        fuelTypeCode = 1 // Electric → enviar código 1
                        print("   Detected ELECTRIC -> API code: 1 (INVERTED)")
                    @unknown default:
                        fuelTypeCode = 1
                    }
                } else {
                    // Lógica normal (según documentación)
                    switch fuel {
                    case .gas:
                        fuelTypeCode = 1 // Fossil fuel
                        print("   Detected GAS -> API code: 1")
                    case .electric:
                        fuelTypeCode = 2 // Electric
                        print("   Detected ELECTRIC -> API code: 2")
                    @unknown default:
                        fuelTypeCode = 1
                        print("   Unknown fuel type, defaulting to GAS (1)")
                    }
                }
                
                print("   API Parameters:")
                print("      bilsize = \(vehicleSize)")
                print("      litenbiltype = \(fuelTypeCode)")
                print("      autopass = \(hasAutoPassAgreement)")
                
                let waypointBody = WaypointRequest(
                    fra: Waypointlist(latitude: origin.latitude, longitude: origin.longitude, time: nil),
                    til: Waypointlist(latitude: destination.latitude, longitude: destination.longitude, time: nil),
                    dato_yyyymmdd: dateString,
                    tidspunkt_hhmm: timeString,
                    bilsize: vehicleSize,
                    litenbiltype: fuelTypeCode,
                    retur: 0,
                    tidsreferanser: 1
                )
                
                // Llamar a TU servicio
                let response = try await BompengerService.shared.getFeesByWaypoint(body: waypointBody)
                
                print("API Response received:")
                print("   Tur array count: \(response.tur?.count ?? 0)")
                
                // Log AMBOS precios SIEMPRE para comparar
                let prices = response.getPrices()
                print("   API Prices:")
                print("      WITHOUT autopass (Kostnad): \(prices.withoutAutopass ?? 0) NOK")
                print("      WITH autopass (Rabattert): \(prices.withAutopass ?? 0) NOK")
                print("   Your autopass setting: \(hasAutoPassAgreement ? "ON" : "OFF")")
                
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
                    isEstimatedPrice = false // Precio real del API
                    
                    print("SUCCESS - Selected price: \(apiTotalPrice) NOK")
                    print("   (Toll count: \(tollsOnRoute.count), Per toll: \(String(format: "%.1f", pricePerToll)) NOK)")
                    print("")
                    
                    // Guardar en cache por 24 horas
                    storage.save(using: modelContext, key: key, total: apiTotalPrice, charges: charges, ttlHours: 24)
                    
                } else {
                    print(" FeeVM: API returned no price, using local calculation")
                    isLoadingPrices = false
                    useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
                }
                
            } catch {
                print("FeeVM: API call failed - \(error.localizedDescription)")
                print("   Using local calculation as fallback")
                isLoadingPrices = false
                useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
            }
        }
    }
    
    //  Fallback Local
    
    // Usa cálculo local si la API no está disponible
    private func useFallbackCalculation(
        tollsOnRoute: [Vegobjekt],
        vehicle: VehicleType,
        fuel: FuelType,
        storage: FeeStorageViewModel,
        modelContext: ModelContext,
        key: String
    ) {
        // Intentar cargar cache expirado
        storage.loadExpired(using: modelContext, key: key)
        
        if let expired = storage.calculation {
            // Usar precio real antiguo (mejor que inventar)
            totalPrice = expired.total
            tollCharges = storage.decodeCharges(expired)
            lastFeeUpdate = expired.createdAt
            isEstimatedPrice = true
            print("FeeVM: Using expired cache as fallback: \(totalPrice) NOK (from \(expired.createdAt))")
        } else {
            // No hay datos — mostrar precio no disponible
            totalPrice = 0
            tollCharges = []
            lastFeeUpdate = nil
            isEstimatedPrice = true
            print("FeeVM: No cached data available, price unavailable")
        }
        
//        let pricePerToll = TollPriceCalculator.calculateTollPrice(
//            vehicleType: vehicle,
//            fuelType: fuel,
//            hasAutopass: hasAutoPassAgreement
//        )
//        
//        let charges = tollsOnRoute.map { v in
//            let name = v.egenskaper.first(where: { $0.navn == "Navn bomstasjon"})?.verdi ?? "Ukjent"
//            return TollCharge(id: "\(v.id)", toll: name, price: pricePerToll)
//        }
//        let total = charges.reduce(0) { $0 + $1.price }
//        
//        totalPrice = total
//        tollCharges = charges
//        lastFeeUpdate = Date()
//        isEstimatedPrice = true // Precio estimado (fallback local)
//        
//        print("FeeVM: Using local calculation (estimated): \(total) NOK")
        
//        // Guardar en cache
//        storage.save(using: modelContext, key: key, total: total, charges: charges, ttlHours: 24)
    }
}


