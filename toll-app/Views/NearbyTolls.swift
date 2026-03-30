//
//  NearbyTolls.swift
//  toll-app
//
//  Created by Carolina Mera  on 09/09/2025.
// 

import SwiftUI
import CoreLocation

struct NearbyTolls: View {
    
    @ObservedObject var mapVm: MapViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Callback cuando se toca un peaje
    var onTollTapped: ((Vegobjekt) -> Void)?
    
    // Propiedad para saber si hay peajes (para usar en el padre)
    var hasNearbyTolls: Bool {
        !nearbyTolls.isEmpty
    }
    
    // Computed property para obtener los peajes cercanos basados en la ubicación del usuario
    private var nearbyTolls: [Vegobjekt] {
        guard let userLocation = mapVm.userLocation else { return [] }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        // Filtrar peajes que estén dentro de 50km (50,000 metros)
        let maxDistance: Double = 50_000
        
        let nearby = mapVm.toll.filter { toll in
            guard let coordinates = toll.lokasjon?.coordinates else { return false }
            let tollLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            let distance = userCLLocation.distance(from: tollLocation)
            return distance <= maxDistance
        }
        
        // Ordenar por distancia (más cercanos primero)
        return nearby.sorted { toll1, toll2 in
            guard let dist1 = toll1.distanceInMeters(from: userLocation),
                  let dist2 = toll2.distanceInMeters(from: userLocation) else { return false }
            return dist1 < dist2
        }
    }
    
    
    // Helper para calcular distancia en formato legible
    private func getDistance(to toll: Vegobjekt) -> String {
        guard let userLocation = mapVm.userLocation else { return "—" }
        return toll.distance(from: userLocation)
    }
    
    var body: some View {
        if nearbyTolls.isEmpty {
            // Estado vacío - sin card de fondo
            VStack(spacing: 12) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                
                Text("No nearby tolls")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(mapVm.userLocation == nil ? "Location not available" : "No tolls within 50 km")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            // Hay peajes - mostrar con scroll horizontal
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nearbyTolls.prefix(10)) { toll in
                        Button {
                            onTollTapped?(toll)
                        } label: {
                            TollCard(
                                name: toll.displayName,
                                distance: getDistance(to: toll),
                                colorScheme: colorScheme
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}


private struct TollCard: View {
    let name: String
    let distance: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text(distance)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            // Indicador visual de que es tocable
            HStack(spacing: 4) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Navigate")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(14)
        .frame(width: 180, height: 120)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 6, x: 0, y: 2)
    }
}
                    
