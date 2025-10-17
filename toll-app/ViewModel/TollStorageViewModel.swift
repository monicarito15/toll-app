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
    
    @Published var tolls: [Vegobjekt] = [] // @Published avisa a los views cuando cambian los datos (para actualizar la UI)
    
    

    // Función principal que carga los datos desde la base de datos local- si no hay datos locales, llama a la api para obtenerlos
    func loadTolls(using modelContext : ModelContext ) async {
        printLastTollUpdateDate() // Muestra la fecha de última actualización en la terminal
        //await updateTollsIfNeeded(using: modelContext) // Espera a que termine la actualización si es necesario
        do {
            //Crear un descriptor para obtener todos los objetos Vegobjekt
            let descriptor = FetchDescriptor<Vegobjekt>()
            
            //Cargar los objetos locales guardados (si existen)
            tolls = try modelContext.fetch(descriptor)
            
            // Si la base local está vacía, traer los datos de la API
            if tolls.isEmpty {
                print("No local tolls found, fetching from API")
                try await fetchAndSaveFromApi(using: modelContext)
            } else {
                //Si encontró datos locales, lo muestra en la consola
                print("Loaded tolls from (local DataBase)SwiftData - Total Found local:)(\(tolls.count))")
            }
            
        } catch {
            print("Error loading from SwitfData dataBase: \(error)")
        }
    }
        
        
        //Función que trae los peajes desde la API y los guarda localmente en SwiftData database
        private func fetchAndSaveFromApi(using modelContext: ModelContext) async throws {
            print("Fetching tolls from API")
            
            // Llama tollservice , llama a la API
            let apiTolls = try await TollService.shared.getTolls()
            print("Received \(apiTolls.count) tolls from API")

            //Limpia los datos viejos de SwiftData
                for toll in try modelContext.fetch(FetchDescriptor<Vegobjekt>()) {
                    modelContext.delete(toll)
                }
                print("Cleared old toll data from SwiftData")
            
            // Crea nuevas instancias válidas y guardarlas
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

                   // Solo inserta si newLokasjon no es nil
                   let newToll = Vegobjekt(id: apiToll.id, href: apiToll.href, egenskaper: newEgenskaper, lokasjon: newLokasjon)
                   modelContext.insert(newToll)
                   insertedCount += 1
                   print("Saved toll: \(newToll.id) - \(newToll.egenskaper.first?.verdi ?? "Unknown")")
               }
               print("Inserted \(insertedCount) new tolls into SwiftData")
            
            // Guarda los cambios
                do {
                    try modelContext.save()
                    print("Saved successfully in the swiftData database")
                } catch {
                    print("Error saving tolls in SwiftData: \(error)")
                }

                //Actualiza la lista publicada (para la UI) haciendo un fetch real de la base local
                do {
                    let descriptor = FetchDescriptor<Vegobjekt>()
                    tolls = try modelContext.fetch(descriptor)
                    print("Saved and loaded \(tolls.count) tolls into memory from SwiftData")
                } catch {
                    print("Error fetching tolls after save: \(error)")
                }
            }
    
    func printLastTollUpdateDate() {
        let lastUpdate = UserDefaults.standard.object(forKey: "lastTollUpdate") as? Date
        if let lastUpdate = lastUpdate {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy HH:mm"
            print("Last toll update date from API: \(formatter.string(from: lastUpdate))")
        } else {
            print("Last toll update date from API: Not found record")
        }
    }
    
    
    // Funcion que llama a la API solo si ha pasado más de un mes desde la última actualización
    func shouldUpdateFromAPI() -> Bool {
        let lastUpdate = UserDefaults.standard.object(forKey: "lastTollUpdate") as? Date ?? .distantPast
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return lastUpdate < oneMonthAgo
        
    }
    func updateTollsIfNeeded(using modelContext: ModelContext) async {
        if shouldUpdateFromAPI() {
            try? await fetchAndSaveFromApi(using: modelContext)
            UserDefaults.standard.set(Date(), forKey: "lastTollUpdate")
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy HH:mm"
            print("Tolls updated from API. Fecha guardada: \(formatter.string(from: Date()))")
        }
        
    }
    
    }
