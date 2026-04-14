//
//  PurchaseManager.swift
//  toll-app
//
//  Manages StoreKit 2 purchases and free search limit.

import SwiftUI
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {

    static let productID = "no.carolina.toll-app.unlimited"
    static let freeSearchLimit = 10

    @Published var isPremium: Bool = false
    @Published var searchesUsed: Int = 0

    var searchesRemaining: Int {
        max(0, Self.freeSearchLimit - searchesUsed)
    }

    var canSearch: Bool {
        isPremium || searchesUsed < Self.freeSearchLimit
    }

    private func resetIfNewMonth() {
        let now = Date()
        let calendar = Calendar.current
        let lastReset = UserDefaults.standard.object(forKey: "searchesResetDate") as? Date ?? .distantPast
        if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
            searchesUsed = 0
            UserDefaults.standard.set(0, forKey: "searchesUsed")
            UserDefaults.standard.set(now, forKey: "searchesResetDate")
        } else {
            searchesUsed = UserDefaults.standard.integer(forKey: "searchesUsed")
        }
    }

    private var updates: Task<Void, Never>?

    init() {
        updates = Task {
            for await result in Transaction.updates {
                if case .verified(let tx) = result, tx.productID == Self.productID {
                    isPremium = true
                    await tx.finish()
                }
            }
        }
        resetIfNewMonth()
        Task { await checkPremiumStatus() }
    }

    deinit {
        updates?.cancel()
    }

    func recordSearch() {
        guard !isPremium else { return }
        searchesUsed += 1
        UserDefaults.standard.set(searchesUsed, forKey: "searchesUsed")
    }

    func purchase() async throws {
        let products = try await Product.products(for: [Self.productID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        if case .success(let verification) = result,
           case .verified(let tx) = verification {
            isPremium = true
            await tx.finish()
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPremiumStatus()
        } catch {
            #if DEBUG
            print("Restore failed: \(error)")
            #endif
        }
    }

    private func checkPremiumStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.productID {
                isPremium = true
                return
            }
        }
    }
}
