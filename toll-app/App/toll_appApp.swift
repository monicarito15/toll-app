import SwiftUI
import SwiftData

@main
struct toll_appApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Vegobjekt.self,
            Egenskap.self,
            Lokasjon.self,
            Geometri.self,
            RecentSearch.self,
            SearchHistoryItem.self,
            FeeCalculation.self
        ])
        
        do {
            modelContainer = try ModelContainer(for: schema)
        } catch {
            // If the database is corrupted, delete it and try again
            print("SwiftData failed to load: \(error). Attempting to reset...")
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            do {
                modelContainer = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer)
        }
    }
}
