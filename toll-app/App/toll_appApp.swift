import SwiftUI
import SwiftData

@main
struct toll_appApp: App {
    // Crear el contenedor de modelos SwiftData
    let modelContainer: ModelContainer = try! ModelContainer(for:
        Vegobjekt.self,
        Egenskap.self,
        Lokasjon.self,
        Geometri.self
    )

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer) // inyecta el context en todas las vistas
        }
    }
}

