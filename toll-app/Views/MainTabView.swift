import SwiftUI

struct MainTabView: View {
    @State private var showSheet = false
    @State private var selectedTab = 0
    @State private var didAppearOnce = false // para saber si ya se abrio el sheet alguna vez
    
    @State private var currentDetent: PresentationDetent = .medium // padre del estado del tamano global



    var body: some View {
        //logica para resetear el sheet si ya esta abierto
        let tabBinding = Binding<Int>( // Create a binding to monitor tab changes
            get: { selectedTab },
            set: { newValue in
                if newValue == 0 {
                    if didAppearOnce {
                        showSheet = false // cierra el sheet si ya se habia abierto antes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // espera 0.1 segundos para que el swiftui tenga para procesar el cambio de tab
                            showSheet = true
                            
                        }
                    } else {
                        showSheet = true // la primera vez que se abre el tab, abre el sheet
                        didAppearOnce = true
                    }
                }
                selectedTab = newValue
            }
        )
        TabView(selection: tabBinding) {
            SearchView(showSheet: $showSheet, currentDetent: $currentDetent)
                .tabItem {
                    Label("Travel", systemImage: "magnifyingglass.circle.fill")
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
        /*.sheet(isPresented: $showSheet) {
         
            CalculatorView(currentDetent: $currentDetent,onCalculate: { _from, _to in
                
            })
            .presentationDetents([.medium, .large], selection: $currentDetent)
        }*/
    }
}
#Preview {
    MainTabView()
}
