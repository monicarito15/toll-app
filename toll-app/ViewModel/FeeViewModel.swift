
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
    @Published var isEstimatedPrice: Bool = false
    
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
            isEstimatedPrice = false
            #if DEBUG
            print("FeeVM: Using cached prices: \(totalPrice) NOK")
            #endif
            return
        }
        
        // 2. No hay cache válido, llamar a la API
        guard let origin = originCoordinate, let destination = destinationCoordinate else {
            #if DEBUG
            print("FeeVM: Warning - Missing coordinates for API call, using local calculation")
            #endif
            useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
            return
        }
        
        // 3. Llamar a BompengerService (API)
        isLoadingPrices = true
        
        Task { @MainActor in
            do {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let dateString = dateFormatter.string(from: date)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HHmm"
                let timeString = timeFormatter.string(from: date)
                
                // bilsize: 1 = Small vehicle (car/motorcycle), 2 = Large vehicle (truck/van)
                // litenbiltype: 1 = Fossil fuel (gas/diesel), 2 = Electric
                let vehicleSize = 1
                
                let fuelTypeCode: Int
                switch fuel {
                case .gas:
                    fuelTypeCode = 1
                case .electric:
                    fuelTypeCode = 2
                @unknown default:
                    fuelTypeCode = 1
                }
                
                #if DEBUG
                print("FeeVM: Calling Bompenger API")
                print("   From: \(origin.latitude), \(origin.longitude)")
                print("   To: \(destination.latitude), \(destination.longitude)")
                print("   Date: \(dateString), Time: \(timeString)")
                print("   Vehicle: \(vehicle.rawValue), Fuel: \(fuel.rawValue)")
                print("   Autopass: \(hasAutoPassAgreement ? "YES" : "NO")")
                print("   bilsize=\(vehicleSize), litenbiltype=\(fuelTypeCode)")
                #endif
                
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
                
                let response = try await BompengerService.shared.getFeesByWaypoint(body: waypointBody)
                
                #if DEBUG
                let prices = response.getPrices()
                print("FeeVM: API Prices - Without autopass: \(prices.withoutAutopass ?? 0), With autopass: \(prices.withAutopass ?? 0)")
                #endif
                
                // Try to get individual toll charges from API
                let apiCharges = response.getTollCharges(hasAutopass: hasAutoPassAgreement)
                
                if !apiCharges.isEmpty {
                    let apiTotalPrice = response.getPrice(hasAutopass: hasAutoPassAgreement) ?? apiCharges.reduce(0) { $0 + $1.price }
                    
                    totalPrice = apiTotalPrice
                    tollCharges = apiCharges
                    lastFeeUpdate = Date()
                    isLoadingPrices = false
                    isEstimatedPrice = false
                    
                    #if DEBUG
                    print("FeeVM: SUCCESS - \(apiTotalPrice) NOK (\(apiCharges.count) tolls from API)")
                    for charge in apiCharges {
                        print("   \(charge.toll): \(charge.price) kr")
                    }
                    #endif
                    
                    storage.save(using: modelContext, key: key, total: apiTotalPrice, charges: apiCharges, ttlHours: 24)
                    
                } else if let apiTotalPrice = response.getPrice(hasAutopass: hasAutoPassAgreement) {
                    // Fallback: API has total but no individual stations
                    let charges = tollsOnRoute.map { v in
                        let name = v.egenskaper.first(where: { $0.navn == "Navn bomstasjon"})?.verdi ?? "Ukjent"
                        return TollCharge(id: "\(v.id)", toll: name, price: apiTotalPrice / Double(tollsOnRoute.count))
                    }
                    
                    totalPrice = apiTotalPrice
                    tollCharges = charges
                    lastFeeUpdate = Date()
                    isLoadingPrices = false
                    isEstimatedPrice = false
                    
                    storage.save(using: modelContext, key: key, total: apiTotalPrice, charges: charges, ttlHours: 24)
                    
                } else {
                    #if DEBUG
                    print("FeeVM: API returned no price, using fallback")
                    #endif
                    isLoadingPrices = false
                    useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
                }
                
            } catch {
                #if DEBUG
                print("FeeVM: API call failed - \(error.localizedDescription)")
                #endif
                isLoadingPrices = false
                useFallbackCalculation(tollsOnRoute: tollsOnRoute, vehicle: vehicle, fuel: fuel, storage: storage, modelContext: modelContext, key: key)
            }
        }
    }
    
    private func useFallbackCalculation(
        tollsOnRoute: [Vegobjekt],
        vehicle: VehicleType,
        fuel: FuelType,
        storage: FeeStorageViewModel,
        modelContext: ModelContext,
        key: String
    ) {
        storage.loadExpired(using: modelContext, key: key)
        
        if let expired = storage.calculation {
            totalPrice = expired.total
            tollCharges = storage.decodeCharges(expired)
            lastFeeUpdate = expired.createdAt
            isEstimatedPrice = true
            #if DEBUG
            print("FeeVM: Using expired cache as fallback: \(totalPrice) NOK")
            #endif
        } else {
            totalPrice = 0
            tollCharges = []
            lastFeeUpdate = nil
            isEstimatedPrice = true
            #if DEBUG
            print("FeeVM: No cached data available, price unavailable")
            #endif
        }
    }
}
