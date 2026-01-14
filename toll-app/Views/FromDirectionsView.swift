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
    @Binding var currentDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

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

                                Task {
                                    await viewModel.saveSearch(name, address: address, using: modelContext)

                                    DispatchQueue.main.async {
                                        viewModel.searchResults = []
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .onChange(of: searchText) { value, _ in
                            viewModel.searchAddresses(query: value)
                        }
                        .padding()
                        .cornerRadius(5)
                }
                .padding(12)
                .background(Color(.systemGray6))

                //UNA sola List con secciones
                List {
                    // Search results
                    if !viewModel.searchResults.isEmpty {
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
                                    searchText = name

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
                                    searchText = item.name
                                    viewModel.searchAddresses(query: item.name)

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
                    Text("Directions")
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

