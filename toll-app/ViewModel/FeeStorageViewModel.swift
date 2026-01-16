//
//  FeesCalStorageViewModel.swift
//  toll-app
//
//  Created by Carolina Mera  on 16/01/2026.
// Read el calculo guardado - guarda el calculo nuevo y verifica si sigue valido 24H

import SwiftUI
import SwiftData

@MainActor
final class FeeStorageViewModel: ObservableObject {

    @Published var calculation: FeeCalculation?

    func load(using modelContext: ModelContext, key: String) {
        do {
            let descriptor = FetchDescriptor<FeeCalculation>(
                predicate: #Predicate { $0.key == key }
            )
            calculation = try modelContext.fetch(descriptor).first
        } catch {
            print("Error loading FeeCalculation:", error)
            calculation = nil
        }
    }

    func isValid(_ calc: FeeCalculation) -> Bool {
        calc.validUntil > Date()
    }

    func decodeCharges(_ calc: FeeCalculation) -> [TollCharge] {
        (try? JSONDecoder().decode([TollCharge].self, from: calc.chargesJSON)) ?? []
    }

    func save(
        using modelContext: ModelContext,
        key: String,
        total: Double,
        charges: [TollCharge],
        ttlHours: Int = 24
    ) {
        let now = Date()
        let validUntil = now.addingTimeInterval(TimeInterval(ttlHours) * 3600)
        let json = (try? JSONEncoder().encode(charges)) ?? Data()

        do {
            let descriptor = FetchDescriptor<FeeCalculation>(
                predicate: #Predicate { $0.key == key }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                existing.total = total
                existing.chargesJSON = json
                existing.createdAt = now
                existing.validUntil = validUntil
            } else {
                let newCalc = FeeCalculation(
                    key: key,
                    total: total,
                    chargesJSON: json,
                    createdAt: now,
                    validUntil: validUntil
                )
                modelContext.insert(newCalc)
            }

            try modelContext.save()
        } catch {
            print("Error saving FeeCalculation:", error)
        }
    }
}



