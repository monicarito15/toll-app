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
final class SearchAddressViewModel : ObservableObject {
        
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
        guard !name.isEmpty else { return }
        
        // Buscar si ya existe en la base de datos
        let descriptor = FetchDescriptor<RecentSearch>()
        let allSearches = (try? context.fetch(descriptor)) ?? []
        
        // Eliminar duplicado existente si lo hay
        if let existing = allSearches.first(where: {
            $0.name.lowercased() == name.lowercased() &&
            $0.address.lowercased() == address.lowercased() 
        }) {
            print("Removing existing search: \(name)")
            context.delete(existing)
        }
        
        // Crear y guardar el nuevo objeto (siempre con fecha actual)
        let newSearch = RecentSearch(name: name, address: address)
        print("Inserting new search: \(name) - \(address)")
        context.insert(newSearch)
        
        do {
            try context.save()
            
            // Recargar y mantener solo las 5 más recientes
            await loadRecentSearch(using: context)
            
            // Si después de recargar hay más de 5, eliminar las antiguas
            let allAfterSave = (try? context.fetch(FetchDescriptor<RecentSearch>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            ))) ?? []
            
            if allAfterSave.count > 5 {
                let toDelete = Array(allAfterSave.dropFirst(5))
                for oldSearch in toDelete {
                    print("Deleting old search: \(oldSearch.name)")
                    context.delete(oldSearch)
                }
                try context.save()
                await loadRecentSearch(using: context)
            }
        } catch {
            print("Error saving search: \(error)")
        }
    }
    
    
    // Carga las busquedas guardadas, las 5 más recientes
    func loadRecentSearch(using context: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<RecentSearch>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let fetched = try context.fetch(descriptor)
            
            // Tomar solo las 5 más recientes y eliminar duplicados
            var seen = Set<String>()
            recentSearches = fetched.filter { search in
                let key = "\(search.name.lowercased())|\(search.address.lowercased())"
                return seen.insert(key).inserted
            }.prefix(5).map { $0 }
            
            print("Loaded \(recentSearches.count) recent searches")
            
        } catch {
            print("Error fetching recent searches: \(error)")
        }
    }
}
