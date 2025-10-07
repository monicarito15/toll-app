//
//  ToDirections.swift
//  toll-app
//
//  Created by Carolina Mera  on 24/09/2025.
//
// This is a view for searching directions with a search bar and a title. Have sheet presentation detents for medium and large sizes. Activate with ToDirections button.

import SwiftUI
import MapKit


struct ToDirectionsView : View {
    
    @Binding var searchText : String
    @Binding var currentDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var locationManager = LocationManager()
    @State private var searchResults: [MKMapItem] = []
    
    @State private var recentSearches: [String] = []
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()
    
  
    
    var body: some View {
        
        NavigationView {
            
            VStack (alignment: .leading){
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                        .onSubmit { // al hacer enter dismiss y regresa al main sheet
                            dismiss()
                            saveSearch(searchText)
                        }
                        .padding()
                        .cornerRadius(5)
                        .onChange(of: searchText) { value, _ in
                                        searchAddresses(query: value)
                                                }
                       
                    
                }
                .padding(12)
                .background(Color(.systemGray6))
                
                
                
                // Muestra las busquedas mas recientes solo si no se esta escribiendo
                if !recentSearches.isEmpty && searchText.isEmpty { // solo muestra: si el recentsearch no esta vacio y el searchtext esta vacio
                    VStack (alignment: .leading) {
                        Text("Recent search")
                            .padding()
                            .font(.headline .bold())
                            .foregroundColor(.gray)
                        
                        ForEach(recentSearches, id: \.self) { item in
                            Text(item)
                                .padding()
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                                .onTapGesture {
                                    searchText = item // Coloca esa búsqueda en el campo de texto
                                    searchAddresses(query: item) // Ejecuta la función de búsqueda con ese texto
                                }
                               
                                                
                        }
                       

                    }
                    
                    
                }
                
                // lista de las direcciones
                List(searchResults, id: \.self) { item in
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Unknown")
                            .font(.headline)
                        Text(item.placemark.title ?? "No Address")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                    .onTapGesture {
                        // Acción al seleccionar una dirección
                        searchText = item.name ?? ""
                        saveSearch(item.name ?? "")
                        
                        searchResults = [] // Borra los resultados de búsqueda
                        dismiss() // cierra el sheet al seleccionar la direccion
                    }
                    
                    
                } //End list
                
               
            
                
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Directions")
                            .font(.system(size:30, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                .presentationDetents([.medium, .large], selection: $currentDetent)
                .onAppear {
                    currentDetent = .large
                    searchText = "" //clear the textfiel search
                    loadRecentSearch()
                }
            }
        }
    }
            
            
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
                searchResults = items
            } else {
                searchResults = []
            }
        }
    }
    
    // Guarda una nueva busqueda
    func saveSearch(_ text: String){
        guard !text.isEmpty else { return } // Si el texto está vacío, no hace nada (evita guardar cadenas vacías)
        if !recentSearches.contains(text){ // Solo guarda si la búsqueda no está repetida
            recentSearches.insert(text, at:0) // lo agrega al principio
            if recentSearches.count > 5 { // Si hay más de 5 búsquedas guardadas
                recentSearches.removeLast()
            }
            // Convierte la lista recentSearches en datos (Data) usando JSON para guardarla en UserDefaults
            if let data = try? JSONEncoder().encode(recentSearches) {
                recentSearchesData = data // // Guarda esos datos codificados en @AppStorage
            }
        }
    }
    
    // Carga las busquedas guardadas
    func loadRecentSearch(){
        // Intenta decodificar (leer) la lista guardada en @AppStorage
        if let decoded = try? JSONDecoder().decode([String].self, from: recentSearchesData) {
            recentSearches = decoded // Si la decodificación funciona, asigna las búsquedas guardadas a la variable recentSearches
        }
    }
    
    
}
        
    


