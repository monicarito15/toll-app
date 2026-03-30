//
//  TollStorageViewModel.swift
//  toll-app
//
//  Created by Carolina Mera  on 08/10/2025.
// Logica que guarda local los tolls

import SwiftUI
import SwiftData

@MainActor
final class TollStorageViewModel : ObservableObject {
    
    @Published var tolls: [Vegobjekt] = []

    func loadTolls(using modelContext: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<Vegobjekt>()
            tolls = try modelContext.fetch(descriptor)
            
            if tolls.isEmpty {
                #if DEBUG
                print("No local tolls found, fetching from API")
                #endif
                try await fetchAndSaveFromApi(using: modelContext)
            } else {
                #if DEBUG
                print("Loaded \(tolls.count) tolls from SwiftData")
                #endif
            }
        } catch {
            #if DEBUG
            print("Error loading from SwiftData: \(error)")
            #endif
        }
    }
        
    private func fetchAndSaveFromApi(using modelContext: ModelContext) async throws {
        let apiTolls = try await TollService.shared.getTolls()
        #if DEBUG
        print("Received \(apiTolls.count) tolls from API")
        #endif

        for toll in try modelContext.fetch(FetchDescriptor<Vegobjekt>()) {
            modelContext.delete(toll)
        }
        
        var insertedCount = 0
        for apiToll in apiTolls {
            let newEgenskaper = apiToll.egenskaper.map { eg in
                Egenskap(id: eg.id, navn: eg.navn, verdi: eg.verdi)
            }

            var newLokasjon: Lokasjon? = nil
            if let oldLokasjon = apiToll.lokasjon {
                let geo = Geometri(wkt: oldLokasjon.geometri.wkt, srid: oldLokasjon.geometri.srid)
                newLokasjon = Lokasjon(geometri: geo)
            }

            let newToll = Vegobjekt(id: apiToll.id, href: apiToll.href, egenskaper: newEgenskaper, lokasjon: newLokasjon)
            modelContext.insert(newToll)
            insertedCount += 1
        }
        #if DEBUG
        print("Inserted \(insertedCount) new tolls into SwiftData")
        #endif
        
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Error saving tolls in SwiftData: \(error)")
            #endif
        }

        do {
            let descriptor = FetchDescriptor<Vegobjekt>()
            tolls = try modelContext.fetch(descriptor)
            #if DEBUG
            print("Loaded \(tolls.count) tolls into memory from SwiftData")
            #endif
        } catch {
            #if DEBUG
            print("Error fetching tolls after save: \(error)")
            #endif
        }
    }
    
    func shouldUpdateFromAPI() -> Bool {
        let lastUpdate = UserDefaults.standard.object(forKey: "lastTollUpdate") as? Date ?? .distantPast
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return lastUpdate < oneMonthAgo
    }

    func updateTollsIfNeeded(using modelContext: ModelContext) async {
        if shouldUpdateFromAPI() {
            try? await fetchAndSaveFromApi(using: modelContext)
            UserDefaults.standard.set(Date(), forKey: "lastTollUpdate")
            #if DEBUG
            print("Tolls updated from API")
            #endif
        }
    }
}
