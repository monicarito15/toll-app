//
//  ToDirections.swift
//  toll-app
//
//  Created by Carolina Mera  on 24/09/2025.
//
// This is a view for searching directions with a search bar and a title. Have sheet presentation detents for medium and large sizes. Activate with ToDirections button.

import SwiftUI
import MapKit
import SwiftData

struct ToDirectionsView : View {
    
    @StateObject private var viewModel = ToDirectionsViewModel()

    @Binding var searchText : String
    @Binding var currentDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    
    var body: some View {
        
        NavigationView {
            VStack (alignment: .leading){
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                        .onSubmit { // al hacer enter dismiss y regresa al main sheet
                            if let first = viewModel.searchResults.first {
                                let name = first.name ?? searchText
                                let address = first.placemark.title ?? searchText
                                Task {
                                    await viewModel.saveSearch(name,address: address, using: modelContext)
                                    
                                }
                                // Limpiar y cerrar
                                DispatchQueue.main.async {
                                    viewModel.searchResults = [] // Borra los resultados de búsqueda
                                    dismiss() // cierra el sheet al seleccionar la direccion
                                }
                            }

                        }
                        .padding()
                        .cornerRadius(5)
                    // Cuando cambia el texto, ejecuta la búsqueda
                        .onChange(of: searchText) { value, _ in
                            viewModel.searchAddresses(query: value)
                                                }
                }
                .padding(12)
                .background(Color(.systemGray6))
                
                
                
                
                // lista de resultados de busqueda (SEARCH DIRECTIONS)
                
                List(viewModel.searchResults, id: \.self) { item in
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Unknown")
                            .font(.headline)
                        Text(item.placemark.title ?? "No Address")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical,2)
                    .onTapGesture {
                        // Acción al seleccionar una dirección
                        let name = item.name ?? "Unknown"
                        let address = item.placemark.title ?? "No Address"
                        searchText = name
                        Task {
                            await viewModel.saveSearch(name,address: address,using: modelContext)
                            
                            DispatchQueue.main.async {
                                viewModel.searchResults = [] // Borra los resultados de búsqueda
                                dismiss() // cierra el sheet al seleccionar la direccion
                            }
                        }
                            
                        
                    }
                    
                    
                } //End list
                
               
                // Muestra(RECENT SEARCH) cuando el campo está vacío
                if !viewModel.recentSearches.isEmpty && searchText.isEmpty { // solo muestra: si el recentsearch no esta vacio y el searchtext esta vacio
                    VStack (alignment: .leading) {
                        Text("Recent search")
                            .padding()
                            .font(.headline .bold())
                            .foregroundColor(.gray)
    
                        
                        // Lista de búsquedas recientes
                        ForEach(viewModel.recentSearches, id: \.self) { item in
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical,6)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity,alignment: .leading )
                            
                                .onTapGesture {                                // Al hacer tap a una búsqueda reciente: vuelve a buscarla

                                    searchText = item.name
                                    viewModel.searchAddresses(query: item.name)
                                    Task {
                                        await viewModel.saveSearch(item.name, address: item.address, using: modelContext)
                                        
                                        
                                        DispatchQueue.main.async {
                                            viewModel.searchResults = [] // Borra los resultados de búsqueda
                                            dismiss() // cierra el sheet al seleccionar la direccion
                                        }
                                    }
                                }
                               
                                                
                        }
                       

                    }
                    
                    
                }
            
        }
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
            }
            .task {
                await viewModel.loadRecentSearch(using: modelContext)
            }
        }
    }
}
        
    


