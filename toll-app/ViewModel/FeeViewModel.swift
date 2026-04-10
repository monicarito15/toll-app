
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
        from: String,
        to: String,
        vehicle: VehicleType,
        fuel: FuelType,
        date: Date
    ) -> String {
        let rounded = roundTo15Min(date)
        // v4: NVDB-based pricing (no external API)
        return "v4|\(from)|\(to)|\(vehicle)|\(fuel)|\(rounded.timeIntervalSince1970)|autopass:\(hasAutoPassAgreement)"
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

        for toll in tollsOnRoute {
            guard var price = toll.price(vehicle: vehicle, fuel: fuel, date: date) else {
                hasAnyMissingPrice = true
                #if DEBUG
                print("FeeVM: No price data for '\(toll.stationName)' — skipped")
                #endif
                continue
            }

            if hasAutoPassAgreement {
                price *= 0.8 // standard 20% autopass discount
            }

            charges.append(TollCharge(
                id: "\(toll.id)",
                toll: toll.stationName,
                price: price
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
        for charge in charges { print("\(charge.toll): \(charge.price) kr") }
        if hasAnyMissingPrice { print("FeeVM: Some stations had no price data") }
        #endif

        if !charges.isEmpty {
            storage.save(using: modelContext, key: key, total: total, charges: charges, ttlHours: 24)
        }
    }
}
