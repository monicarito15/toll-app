//
//  ToDirectionsViewModel.swift
//  toll-app
//
//  Created by Carolina Mera  on 20/10/2025.
//

import SwiftUI
import MapKit
import SwiftData

@MainActor
final class ToDirectionsViewModel : ObservableObject {
        
    @Published var searchResults: [MKMapItem] = []
    @Published var recentSearches: [RecentSearch] = []
    
    private var locationManager = LocationManager()
    
    
    // funcion para buscar la direcciones
    func searchAddresses(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        //Centrar la busqueda en la ubicacion actual
        if let userLocation = locationManager.userLocation{
            request.region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let items = response?.mapItems {
                self.searchResults = items
            } else {
                self.searchResults = []
            }
        }
    }
    
    // Guarda una nueva busqueda - y que se solo guarden las 5 ultimas
    func saveSearch(_ name: String, address: String, using context: ModelContext) async {
        guard !name.isEmpty else { return } // No guarda búsquedas vacías
        recentSearches.removeAll { $0.name.lowercased() == name.lowercased() }
        
        // Evita duplicados
        if recentSearches.contains(where: { $0.name == name && $0.address == address }) {
            print("Duplicate search not saved: \(name) - \(address)") // Nuevo: print de depuración
            return
        }
        
        // Crea y guarda el nuevo objeto
        let newSearch = RecentSearch(name: name, address: address)
        print("Inserting new search: \(name) - \(address)")
     
            context.insert(newSearch)
      
        // Guarda y recarga las 5 últimas
        do {
            try context.save()
            print("Saved new search in SwiftData")
            
            await loadRecentSearch(using: context)// Recarga la lista desde la base

            
            // Si hay más de 5, elimina las más antiguas
            if recentSearches.count > 5 {
                let extras = recentSearches.dropFirst(5)
                for oldSearch in extras {
                    print("Deleting old search: \(oldSearch.name) - \(oldSearch.address)")
                    context.delete(oldSearch)
                }
                try context.save()
                await loadRecentSearch(using: context)
            }
        } catch {
            print("Error saving search: \(error)")
        }
    }
    
    
    // Carga las busquedas guardadas, las 5
    func loadRecentSearch(using context: ModelContext) async {
        
        do {
            var descriptor = FetchDescriptor<RecentSearch>(
                //sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
                
            )
            descriptor.fetchLimit = 5
            let fetched = try context.fetch(descriptor)
            print("Fetched \(fetched.count) recent searches from SwiftData") 
            recentSearches = fetched
            
        } catch {
            print("Error fetching recent searches: \(error)")
        }
        
    }
}
