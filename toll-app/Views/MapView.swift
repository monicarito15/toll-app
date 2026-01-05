//
//  MapView.swift
//  toll-app
//
//  Created by Carolina Mera on 09/10/2025.
// Aqui se ve la linea azul por el moemnto esta de mi locacion aun toll en bergen

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
    @ObservedObject var mapViewModel = MapViewModel()
    
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
                    
                    // la polilínea representa la ruta calculada entre `from` y `to`
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
            
            /*Button("Calcular ruta") {
                Task { @MainActor in
                    await mapViewModel.getDirectionsFromAddresses(fromAddress: from, toAddress: to)
                }
            }
            .padding() */
        }
        .onAppear {
            //Cuando la vista aparece, se actualiza la ubicación del usuario
            mapViewModel.updateUserLocation()
            // Si hay direcciones válidas, calcula la ruta entre `from` y `to`
            Task { @MainActor in
                await mapViewModel.getDirectionsFromAddresses(fromAddress: from, toAddress: to)
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


