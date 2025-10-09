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
    
    @StateObject private var mapViewModel = MapViewModel()
   
    var body: some View {
        VStack {
            ZStack {
                Map {
                    
                    if let userLocation = mapViewModel.userLocation {
                        Marker("Mi ubicación", coordinate: userLocation)
                    }
                    
                    // Se muestran los tolls (bomestasjoner).
                    ForEach(mapViewModel.toll) { vegobjekt in
                        if let coordinate = vegobjekt.lokasjon.coordinates {
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
                    
                    // Mostramos la línea de la ruta, si existe.
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
            
            // Botón para calcular la ruta manualmente.
            Button("Calcular ruta") {
                if let userLocation = mapViewModel.userLocation,
                   let firstToll = mapViewModel.toll.first?.lokasjon.coordinates {
                    print("Calcular ruta desde \(userLocation) hasta \(firstToll)")
                    Task {
                        await mapViewModel.getDirections(from: userLocation, to: firstToll)
                    }
                } else {
                    print("No se encontró la ubicación del usuario o ningún toll.")
                }
            }
            .padding()
        }
        .onAppear {
            // Cuando aparece la vista, actualizamos la ubicación del usuario.
            mapViewModel.updateUserLocation()
            
            // Si ya hay ubicación, creamos la ruta hacia la dirección 'to'.
            if let userLocation = mapViewModel.userLocation {
                mapViewModel.getDirectionsToAddress(from: userLocation, toAddress: to)
            }
        }
        .task {
            // Cargamos los tolls desde la API.
            await mapViewModel.fetchTolls()
        }
    }
}

