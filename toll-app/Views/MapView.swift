//
//  MapView.swift
//  toll-app
//
//  Created by Carolina Mera on 09/10/2025.

import SwiftUI
import MapKit
import CoreLocation
import ArcGIS

struct MapView: View {
    
    let from: String
    let to: String
    let vehicleType: VehicleType
    let fuelType: FuelType
    let dateTime: Date
    
    
    // ahora usamos el ViewModel, que contiene toda la lógica de ubicación, rutas y tolls
    @ObservedObject var mapViewModel : MapViewModel
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var tollStorageVM = TollStorageViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    @State private var showDetailsSheet = false

   
    var body: some View {
        VStack {
            ZStack {
                Map(position: $cameraPosition) {
                    
                    // user location
                    if let userLocation = mapViewModel.userLocation {
                        // Center map on user location
                        Marker("My location", coordinate: userLocation)
                    }
                    
                    // tolls
                    ForEach(mapViewModel.tollsOnRoute) { vegobjekt in
                        if let coordinate = vegobjekt.lokasjon?.coordinates {
                            let tollName = vegobjekt.egenskaper.first(where: { $0.navn == "Navn bomstasjon" })?.verdi
                            ?? vegobjekt.egenskaper.first(where: { $0.navn == "Navn bompengeanlegg (fra CS)" })?.verdi
                            ?? "Unknown"
                            let labelText = "Toll #\(vegobjekt.id) - \(tollName)"
                            Annotation(labelText, coordinate: coordinate) {
                                Label(labelText, systemImage: "dollarsign.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.system(size:18))
                                    .shadow(radius: 3)
                                    
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
                
                // UI normal: barrita abajo (Solo cuando hay resultado)
                if mapViewModel.hasResult {
                    TollSummaryBar(
                        tollCount: mapViewModel.tollsOnRoute.count,   //
                        total: mapViewModel.totalPrice
                    ) {
                    showDetailsSheet = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
                }
            }
            .animation(.easeInOut, value: mapViewModel.hasResult)
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
        
        // este onChange: mueve cámara + buildResult
        .onChange(of: mapViewModel.route) { _, route in
            guard let route else { return }

            var rect = route.polyline.boundingMapRect

            //Padding cómodo (ajusta a tu gusto)
            rect = rect.insetBy(dx: -1200, dy: -1200)

            //Evita zoom demasiado cerca en rutas cortas
            let minSide: Double = 3000 // metros aprox en MapRect (depende, pero funciona bien como "anti-zoom")
            if rect.size.width < minSide {
                let expand = (minSide - rect.size.width) / 2
                rect = rect.insetBy(dx: -expand, dy: -expand)
            }

            withAnimation(.easeInOut) {
                cameraPosition = .rect(rect)
            }
            
            

        }
        
        .onChange(of: mapViewModel.route) { _, _ in
            mapViewModel.buildResultIfPossible(vehicle: vehicleType, fuel: fuelType, date: dateTime)
        }

        .onChange(of: mapViewModel.toll) { _, _ in
            mapViewModel.buildResultIfPossible(vehicle: vehicleType, fuel: fuelType, date: dateTime)
        }
        
        .sheet(isPresented: $showDetailsSheet) {
            TollPassedListView(tolls: mapViewModel.tollsOnRoute)
                .presentationDetents([.medium, .large])
        }




    }
}


