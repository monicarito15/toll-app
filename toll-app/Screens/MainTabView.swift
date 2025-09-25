import SwiftUI

struct MainTabView: View {
    @State private var showSheet = false
    @State private var selectedTab = 0
    
    @State private var currentDetent: PresentationDetent = .medium // padre del estado del tamano global


    var body: some View {
        //logica para resetear el sheet si ya esta abierto
        let tabBinding = Binding<Int>( // Create a binding to monitor tab changes
            get: { selectedTab },
            set: { newValue in
                if newValue == 0 {
                    showSheet = false // resetea el sheet aunque este abierto,
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // espera 0.1 segundos para que el swiftui tenga para procesar el cambio de tab
                        showSheet = true
                        
                    }
                }
                selectedTab = newValue
            }
        )
        TabView(selection: tabBinding) {
            SearchView(showSheet: $showSheet, currentDetent: $currentDetent)
                .tabItem {
                    Label("Search", systemImage: "location.fill")
                }
                .tag(0)
            VehicleView()
                .tabItem {
                    Label("Vehicles", systemImage: "car.fill")
                }
                .tag(1)
            ProfileView()
                .tabItem{
                    Label("profile", systemImage: "person.fill")
                }
                .tag(2)
            
        }
        .sheet(isPresented: $showSheet) {
         
                CalculatorView(currentDetent: $currentDetent)
            .presentationDetents([.medium, .large], selection: $currentDetent)
        }
    }
}
#Preview {
    MainTabView()
}
