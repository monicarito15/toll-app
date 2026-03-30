//
//  FromDirectionsView.swift
//  toll-app
//
//  Created by Carolina Mera  on 05/01/2026.
//

import SwiftUI
import MapKit
import SwiftData



struct FromDirectionsView: View {

    @StateObject private var viewModel = SearchAddressViewModel()

    @Binding var searchText: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var currentDetent: PresentationDetent
    @Binding var isFromCurrentLocation: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            // Si hay resultados, toma el primero y cierra
                            if let first = viewModel.searchResults.first {
                                let name = first.name ?? searchText
                                let address = first.placemark.title ?? searchText
                                searchText = address
                                selectedCoordinate = first.placemark.coordinate

                                Task {
                                    await viewModel.saveSearch(name, address: address, using: modelContext)

                                    DispatchQueue.main.async {
                                        viewModel.searchResults = []
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .onChange(of: searchText) { _, newValue in
                            viewModel.searchAddresses(query: newValue)
                        }
                        .padding()
                        .cornerRadius(5)
                }
                .padding(12)
                .background(Color(.systemGray6))
            
                // Botón "Your location"
                Button {
                    // Marcar que queremos usar la ubicación actual
                    isFromCurrentLocation = true
                    
                    // Actualizar el searchText con la dirección actual
                    if let address = locationManager.currentAddress {
                        searchText = address
                    } else {
                        // Si aún no tenemos dirección, usar coordenadas
                        if let location = locationManager.userLocation {
                            searchText = String(format: "%.4f, %.4f", location.latitude, location.longitude)
                        }
                        // Solicitar la ubicación si no la tenemos
                        locationManager.requestLocation()
                    }
                    
                    // Cerrar el sheet y volver a CalculatorView
                    dismiss()
                    
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                        
                        Text("Your location")
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Mostrar la dirección actual si está disponible
                        if let address = locationManager.currentAddress {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                //UNA sola List con secciones
                List {
                    // Search results
                    if !viewModel.searchResults.isEmpty && !searchText.isEmpty {
                        Section {
                            ForEach(viewModel.searchResults, id: \.self) { item in
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown")
                                        .font(.headline)
                                    Text(item.placemark.title ?? "No Address")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle()) // hace todo el row clickeable
                                .onTapGesture {
                                    let name = item.name ?? "Unknown"
                                    let address = item.placemark.title ?? "No Address"
                                    searchText = address
                                    selectedCoordinate = item.placemark.coordinate
                                    dismiss()

                                    Task {
                                        await viewModel.saveSearch(name, address: address, using: modelContext)

                                        DispatchQueue.main.async {
                                            viewModel.searchResults = []
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Search results")
                        }
                    }

                    // Recent search (solo cuando el campo está vacío)
                    if !viewModel.recentSearches.isEmpty && searchText.isEmpty {
                        Section {
                            ForEach(viewModel.recentSearches, id: \.self) { item in
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text(item.address)
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    searchText = item.address

                                    Task {
                                        await viewModel.saveSearch(item.name, address: item.address, using: modelContext)

                                        DispatchQueue.main.async {
                                            viewModel.searchResults = []
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Recent search")
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Starting point")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .presentationDetents([.medium, .large], selection: $currentDetent)
            .onAppear {
                currentDetent = .large
                searchText = ""
            }
            .task {
                await viewModel.loadRecentSearch(using: modelContext)
            }
        }
    }
}

