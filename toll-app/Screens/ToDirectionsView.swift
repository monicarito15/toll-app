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
    
    @StateObject private var locationManager = LocationManager()
    @State private var searchResults: [MKMapItem] = []
    
    var body: some View {
        
        NavigationView {
            
            VStack (alignment: .leading){
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.textInputAutocapitalization(.words)
                        .padding()
                        .cornerRadius(5)
                        .onChange(of: searchText) { value, _ in
                            searchAddresses(query: value)
                        }
                    
                }
                .padding(12)
                .background(Color(.systemGray6))
                
                
                
                
                Divider()
                
               
                
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
                        // Cierra el sheet al seleccionar una dirección
                        currentDetent = .medium // Cambia a medium antes de cerrar
                        // Aquí podrías agregar lógica adicional, como actualizar un estado en el padre
                        searchResults = [] // Limpia los resultados de búsqueda
                        
                    }

                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Directions")
                                .font(.system(size:30, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                    
                }
                
                .presentationDetents([.medium, .large], selection: $currentDetent) // usa el mismo binding
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
}
        
    


