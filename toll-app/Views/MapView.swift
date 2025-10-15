//
//  MapView.swift
//  toll-app
//
//  Created by Carolina Mera on 09/10/2025.
//

import SwiftUI
import MapKit
import CoreLocation
import ArcGIS

struct MapView: View {
    
    let from: String
    let to: String
    let vehicleType: String
    let fuelType: String
    let dateTime: Date
    
    // ahora usamos el ViewModel, que contiene toda la lógica de ubicación, rutas y tolls
    @StateObject private var mapViewModel = MapViewModel()
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var tollStorageVM = TollStorageViewModel()

   
    var body: some View {
        VStack {
            ZStack {
                Map() {
                    
                    // user location
                    if let userLocation = mapViewModel.userLocation {
                        // Center map on user location
                        Marker("My location", coordinate: userLocation)
                    }
                    
                    // tolls
                    ForEach(mapViewModel.toll) { vegobjekt in
                        if let coordinate = vegobjekt.lokasjon?.coordinates {
                            let tollName = vegobjekt.egenskaper.first(where: { $0.navn == "Navn bomstasjon" })?.verdi
                                ?? vegobjekt.egenskaper.first(where: { $0.navn == "Navn bompengeanlegg (fra CS)" })?.verdi
                                ?? "Unknown"
                            let labelText = "Toll #\(vegobjekt.id) - \(tollName)"
                            Annotation(labelText, coordinate: coordinate) {
                                Label(labelText, systemImage: "car")
                                    .labelStyle(.iconOnly)
                                    .font(.title)
                                    .shadow(radius: 5)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // route line
                    if let route = mapViewModel.route {
                        MapPolyline(route)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .tint(.red)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                    MapScaleView()
                }
                .mapStyle(.standard(elevation: .realistic))
            }
            
            // Botón para calcular ruta manualmente
            Button("Calcular ruta") {
                if let userLocation = mapViewModel.userLocation,
                   let firstToll = mapViewModel.toll.first?.lokasjon?.coordinates {
                    print("Calculate route from \(userLocation) to \(firstToll)")
                    Task {
                        await mapViewModel.getDirections(from: userLocation, to: firstToll)
                    }
                } else {
                    print("Not found user location and toll")
                }
            }
            .padding()
        }
        .onAppear {
            //Cuando la vista aparece, se actualiza la ubicación del usuario
            mapViewModel.updateUserLocation()
            if let userLocation = mapViewModel.userLocation {
                //Y se calcula la ruta hacia la dirección 'to'
                mapViewModel.getDirectionsToAddress(from: userLocation, toAddress: to )
            }
               
                    Task {
                        await tollStorageVM.loadTolls(using: modelContext)
                    }
                
        }
        .task {
            //Carga los tolls desde la API cuando aparece la vista
            await mapViewModel.fetchTolls()
        }
    }
}

