
// FeeViewModel: cache check → calculate from NVDB egenskaper → expose totalPrice, tollCharges

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
        tollIDs: String,
        vehicle: VehicleType,
        fuel: FuelType,
        date: Date
    ) -> String {
        let rounded = roundTo15Min(date)
        // v6: removed autopass from key (NVDB prices already are AutoPASS prices)
        return "v6|\(tollIDs)|\(vehicle)|\(fuel)|\(rounded.timeIntervalSince1970)"
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

        let tollIDs = tollsOnRoute.map { "\($0.id)" }.sorted().joined(separator: ",")
        let key = feeCalculationKey(tollIDs: tollIDs, vehicle: vehicle, fuel: fuel, date: date)

        // 1. Check cache
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

        // 2. Calculate directly from NVDB egenskaper
        isLoadingPrices = true

        var charges: [TollCharge] = []
        var hasAnyMissingPrice = false

        // Timesregel: pre-compute the most expensive toll per group for "Dyreste passering gjelder"
        var dyrestePerGroup: [Int: Int] = [:]  // groupId -> index of most expensive toll
        for (i, toll) in tollsOnRoute.enumerated() {
            guard let gruppe = toll.timesregelGruppe,
                  toll.timesregel == "Dyreste passering gjelder",
                  let price = toll.price(vehicle: vehicle, fuel: fuel, date: date) else { continue }
            if let bestIdx = dyrestePerGroup[gruppe],
               let bestPrice = tollsOnRoute[bestIdx].price(vehicle: vehicle, fuel: fuel, date: date),
               price <= bestPrice { continue }
            dyrestePerGroup[gruppe] = i
        }

        var seenFirstGroups: Set<Int> = []

        for (i, toll) in tollsOnRoute.enumerated() {
            guard let price = toll.price(vehicle: vehicle, fuel: fuel, date: date) else {
                hasAnyMissingPrice = true
                #if DEBUG
                print("FeeVM: No price data for '\(toll.stationName)' — skipped")
                #endif
                continue
            }

            // Timesregel: skip tolls that are free under the hourly-rule
            if let gruppe = toll.timesregelGruppe, let regel = toll.timesregel, regel != "Ikke timesregel" {
                if regel == "Første passering gjelder" {
                    if seenFirstGroups.contains(gruppe) { continue }
                    seenFirstGroups.insert(gruppe)
                } else if regel == "Dyreste passering gjelder" {
                    if dyrestePerGroup[gruppe] != i { continue }
                }
            }

            let coord = toll.lokasjon?.coordinates
            charges.append(TollCharge(
                id: "\(toll.id)",
                toll: toll.stationName,
                price: price,
                latitude: coord?.latitude,
                longitude: coord?.longitude
            ))
        }

        let total = charges.reduce(0) { $0 + $1.price }

        totalPrice = total
        tollCharges = charges
        lastFeeUpdate = Date()
        isLoadingPrices = false
        isEstimatedPrice = hasAnyMissingPrice

        #if DEBUG
        print("FeeVM: NVDB prices - \(total) NOK (\(charges.count) tolls)")
        for charge in charges { print("   • \(charge.toll): \(charge.price) kr") }
        if hasAnyMissingPrice { print("FeeVM:Some stations had no price data") }
        #endif

        if !charges.isEmpty {
            storage.save(using: modelContext, key: key, total: total, charges: charges, ttlHours: 24)
        }
    }
}
