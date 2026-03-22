import SwiftUI

struct HistoryView: View {
    
    let searchHistory: [SearchHistoryItem]
    let onSelectSearch: (SearchHistoryItem) -> Void
    
    var body: some View {
        NavigationView {
            Group {
                if searchHistory.isEmpty {
                    // Vista cuando no hay historial
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your recent searches will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Lista de búsquedas
                    List {
                        ForEach(searchHistory) { historyItem in
                            Button(action: {
                                onSelectSearch(historyItem)
                            }) {
                                HStack(spacing: 12) {
                                    // Icono de la ruta
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        // Ruta: Origen → Destino
                                        Text(historyItem.routeDescription)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        
                                        // Información adicional
                                        HStack(spacing: 8) {
                                            // Tolls encontrados
                                            if historyItem.tollCount > 0 {
                                                Label("\(historyItem.tollCount) toll\(historyItem.tollCount == 1 ? "" : "s")",
                                                      systemImage: "mappin.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            // Precio total
                                            if historyItem.totalPrice > 0 {
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                Text(String(format: "%.0f kr", historyItem.totalPrice))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        // Cuándo se hizo la búsqueda
                                        Text(historyItem.timeAgo)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Indicador de que es clickeable
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !searchHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(searchHistory.count) search\(searchHistory.count == 1 ? "" : "es")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView(
        searchHistory: [
            SearchHistoryItem(
                fromAddress: "Oslo",
                toAddress: "Trondheim",
                vehicleType: .car,
                fuelType: .gas,
                dateTime: Date(),
                hasAutopass: true,
                totalPrice: 450,
                tollCount: 5
            ),
            SearchHistoryItem(
                fromAddress: "Bergen",
                toAddress: "Stavanger",
                vehicleType: .car,
                fuelType: .electric,
                dateTime: Date().addingTimeInterval(-86400),
                hasAutopass: false,
                totalPrice: 320,
                tollCount: 3
            )
        ],
        onSelectSearch: { _ in }
    )
}


