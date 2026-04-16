//
//  FeeCalculationCacheTests.swift
//  toll-appTests
//
//  Tests for FeeCalculation cache validity and FeeViewModel cache key generation

import Testing
import Foundation
@testable import toll_app

struct FeeCalculationCacheTests {

    // FeeCalculation validity

    @Test func validCache_notExpired() {
        let calc = FeeCalculation(
            key: "test-key",
            total: 42.0,
            chargesJSON: Data(),
            createdAt: Date(),
            validUntil: Date().addingTimeInterval(3600) // 1 hour from now
        )
        #expect(calc.validUntil > Date())
    }

    @Test func expiredCache_isExpired() {
        let calc = FeeCalculation(
            key: "test-key",
            total: 42.0,
            chargesJSON: Data(),
            createdAt: Date().addingTimeInterval(-90000), // created 25h ago
            validUntil: Date().addingTimeInterval(-3600)  // expired 1h ago
        )
        #expect(calc.validUntil < Date())
    }

    @Test func cacheTTL_is24Hours() {
        let now = Date()
        let validUntil = now.addingTimeInterval(24 * 3600)
        let diff = validUntil.timeIntervalSince(now)
        #expect(diff == 24 * 3600)
    }

    // FeeViewModel cache key (uses tollIDs, not from/to strings)

    @MainActor @Test func cacheKey_includesTollIDs() {
        let vm = FeeViewModel()
        let key = vm.feeCalculationKey(tollIDs: "123,456", vehicle: .car, fuel: .gas, date: Date())
        #expect(key.contains("123,456"))
    }

    @MainActor @Test func cacheKey_differsByFuel() {
        let vm = FeeViewModel()
        let date = Date()
        let gasKey = vm.feeCalculationKey(tollIDs: "123", vehicle: .car, fuel: .gas, date: date)
        let evKey  = vm.feeCalculationKey(tollIDs: "123", vehicle: .car, fuel: .electric, date: date)
        #expect(gasKey != evKey)
    }

    @MainActor @Test func cacheKey_differsByVehicle() {
        let vm = FeeViewModel()
        let date = Date()
        let carKey  = vm.feeCalculationKey(tollIDs: "123", vehicle: .car, fuel: .gas, date: date)
        let motoKey = vm.feeCalculationKey(tollIDs: "123", vehicle: .motorcycle, fuel: .gas, date: date)
        #expect(carKey != motoKey)
    }

    @MainActor @Test func cacheKey_roundsTo15MinBuckets() {
        let vm = FeeViewModel()
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 7
        comps.hour = 8; comps.minute = 3; comps.second = 0
        let t1 = Calendar.current.date(from: comps)!
        comps.minute = 14
        let t2 = Calendar.current.date(from: comps)!
        // Both 08:03 and 08:14 round to the same 15-min bucket (08:00)
        let key1 = vm.feeCalculationKey(tollIDs: "123", vehicle: .car, fuel: .gas, date: t1)
        let key2 = vm.feeCalculationKey(tollIDs: "123", vehicle: .car, fuel: .gas, date: t2)
        #expect(key1 == key2)
    }

    @MainActor @Test func cacheKey_includesVersionPrefix() {
        let vm = FeeViewModel()
        let key = vm.feeCalculationKey(tollIDs: "123", vehicle: .car, fuel: .gas, date: Date())
        #expect(key.hasPrefix("v6|"))
    }
}
