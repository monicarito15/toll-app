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
            print("Fetching tolls from API...")
            
            // Llama tollservice , llama a la API
            let apiTolls = try await TollService.shared.getTolls()
            print("Received \(apiTolls.count) tolls from API")

        
            // Clear old data in swiftData(local)
            for toll in try modelContext.fetch(FetchDescriptor<Vegobjekt>()){
                modelContext.delete(toll)
            }
            print("Cleared old toll data from SwiftData")
            
            // Inserta los nuevos peajes uno por uno
            for toll in apiTolls {
                modelContext.insert(toll)
            }
            print("Inserted \(apiTolls.count) new tolls into SwiftData")
            
            //Guarda los cambios en la base de datos
            try modelContext.save()
            print("Saved successfully in the swiftData database")
                
            // Verifica que se guardaron correctamente haciendo un fetch
            let savedTolls = try modelContext.fetch(FetchDescriptor<Vegobjekt>())
            print("Verified \(savedTolls.count) tolls are now in SwiftData")
            
                for toll in savedTolls {
                    print("Saved toll: \(toll.id) - \(toll.egenskaper.first?.verdi ?? "Unknown")")
                }
            
                //Actualiza la lista publicada (para la UI)
                tolls = apiTolls
                print("Saved and loaded \(tolls.count) tolls into memory from SwiftData")
            }
    }
        
        
        
        

    
    
    


