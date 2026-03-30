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
    
    
    func searchAddresses(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Región que cubre toda Noruega
        let norwayCenter = CLLocationCoordinate2D(latitude: 64.5, longitude: 12.0)
        let norwaySpan = MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
        request.region = MKCoordinateRegion(center: norwayCenter, span: norwaySpan)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let items = response?.mapItems {
                self.searchResults = items.filter { item in
                    item.placemark.countryCode == "NO"
                }
            } else {
                self.searchResults = []
            }
        }
    }
    
    func saveSearch(_ name: String, address: String, using context: ModelContext) async {
        guard !name.isEmpty else { return }
        
        let descriptor = FetchDescriptor<RecentSearch>()
        let allSearches = (try? context.fetch(descriptor)) ?? []
        
        if let existing = allSearches.first(where: {
            $0.name.lowercased() == name.lowercased() &&
            $0.address.lowercased() == address.lowercased() 
        }) {
            context.delete(existing)
        }
        
        let newSearch = RecentSearch(name: name, address: address)
        context.insert(newSearch)
        
        do {
            try context.save()
            
            await loadRecentSearch(using: context)
            
            let allAfterSave = (try? context.fetch(FetchDescriptor<RecentSearch>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            ))) ?? []
            
            if allAfterSave.count > 5 {
                let toDelete = Array(allAfterSave.dropFirst(5))
                for oldSearch in toDelete {
                    context.delete(oldSearch)
                }
                try context.save()
                await loadRecentSearch(using: context)
            }
        } catch {
            #if DEBUG
            print("Error saving search: \(error)")
            #endif
        }
    }
    
    
    func loadRecentSearch(using context: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<RecentSearch>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let fetched = try context.fetch(descriptor)
            
            var seen = Set<String>()
            recentSearches = fetched.filter { search in
                let key = "\(search.name.lowercased())|\(search.address.lowercased())"
                return seen.insert(key).inserted
            }.prefix(5).map { $0 }
            
        } catch {
            #if DEBUG
            print("Error fetching recent searches: \(error)")
            #endif
        }
    }
}
