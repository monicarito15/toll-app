import SwiftUI
import MapKit
import SwiftData

struct ToDirectionsView: View {

    @StateObject private var viewModel = SearchAddressViewModel()

    @Binding var searchText: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var currentDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var isFromCurrentLocation: Bool
    @StateObject private var locationManager = LocationManager()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                
                List {
                    if !viewModel.searchResults.isEmpty {
                        Section {
                            ForEach(viewModel.searchResults, id: \.self) { item in
                                searchResultRow(item)
                            }
                        } header: {
                            Text("RESULTS")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }

                    if !viewModel.recentSearches.isEmpty && searchText.isEmpty {
                        Section {
                            ForEach(viewModel.recentSearches) { item in
                                recentRow(item)
                            }
                        } header: {
                            Text("RECENT")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(colorScheme == .dark ? .black : .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Destination")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .presentationDetents([.medium, .large], selection: $currentDetent)
            .onAppear {
                currentDetent = .large
                searchText = ""
                isSearchFocused = true
            }
            .task {
                await viewModel.loadRecentSearch(using: modelContext)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search destination...", text: $searchText)
                .focused($isSearchFocused)
                .onSubmit {
                    if let first = viewModel.searchResults.first {
                        selectMapItem(first)
                    }
                }
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchAddresses(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(.systemGray5) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Rows
    private func searchResultRow(_ item: MKMapItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(.red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                Text(item.placemark.title ?? "No Address")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
            selectMapItem(item)
        }
    }

    private func recentRow(_ item: RecentSearch) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundStyle(.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                Text(item.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
            searchText = item.address
            dismiss()
        }
    }
    
    // MARK: - Actions
    private func selectMapItem(_ item: MKMapItem) {
        let name = item.name ?? searchText
        let address = item.placemark.title ?? searchText
        searchText = address
        selectedCoordinate = item.placemark.coordinate

        Task {
            await viewModel.saveSearch(name, address: address, using: modelContext)
            await MainActor.run {
                viewModel.searchResults = []
                dismiss()
            }
        }
    }
}
