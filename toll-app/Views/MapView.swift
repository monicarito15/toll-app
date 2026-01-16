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
    
    @ObservedObject var mapVM : MapViewModel
    @StateObject private var tollStorageVM = TollStorageViewModel()
    @Environment(\.modelContext) private var modelContext

    
    @StateObject private var feeVM = FeeViewModel()
    @StateObject private var feeStorageVM = FeeStorageViewModel()
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    @State private var showDetailsSheet = false

   
    var body: some View {
        VStack {
            ZStack {
                Map(position: $cameraPosition) {
                    
                    // user location
                    if let userLocation = mapVM.userLocation {
                        // Center map on user location
                        Marker("My location", coordinate: userLocation)
                    }
                    
                    // tolls
                    ForEach(mapVM.tollsOnRoute) { vegobjekt in
                        if let coordinate = vegobjekt.lokasjon?.coordinates {
                            let tollName = vegobjekt.egenskaper.first(where: { $0.navn == "Navn bomstasjon" })?.verdi
                            ?? vegobjekt.egenskaper.first(where: { $0.navn == "Navn bompengeanlegg (fra CS)" })?.verdi
                            ?? "Unknown"
                            let labelText = "Toll #\(vegobjekt.id) - \(tollName)"
                            Annotation(labelText, coordinate: coordinate) {
                                Label(labelText, systemImage: "creditcard.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.system(size:18))
                                    .shadow(radius: 3)
                                    
                            }
                        }
                    }
                    
                    // la polilínea representa la ruta calculada entre `from` y `to`
                    // route line
                    if let route = mapVM.route {
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
                if mapVM.hasResult {
                    TollSummaryBar(
                        tollCount: mapVM.tollsOnRoute.count,
                        total: feeVM.totalPrice
                    ) {
                    showDetailsSheet = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
                }
            }
            .animation(.easeInOut, value: mapVM.hasResult)
        }
            

        
        .onAppear {
            //Cuando la vista aparece, se actualiza la ubicación del usuario
            mapVM.updateUserLocation()
            
            // Si hay direcciones válidas, calcula la ruta entre `from` y `to`
            Task { @MainActor in
                await mapVM.getDirectionsFromAddresses(fromAddress: from, toAddress: to)
            }
               
            Task {
                await tollStorageVM.loadTolls(using: modelContext)
            }
        }
        .task {
            //Carga los tolls desde la API cuando aparece la vista
            await mapVM.fetchTolls()
        }
        
        // este onChange: mueve cámara + buildResult "Solo se ejecuta cuando cambia la ruta"
        .onChange(of: mapVM.route) { _, route in
            guard let route else { return }
            
            var rect = route.polyline.boundingMapRect// Calcula el rectángulo que contiene toda la ruta

            //Añade padding para que la ruta no quede pegada a los bordes
            rect = rect.insetBy(dx: -1200, dy: -1200)

            //Evita zoom demasiado cerca en rutas cortas
            let minSide: Double = 3000
            if rect.size.width < minSide {
                let expand = (minSide - rect.size.width) / 2
                rect = rect.insetBy(dx: -expand, dy: -expand)
            }

            withAnimation(.easeInOut) {
                cameraPosition = .rect(rect)
            }

        }
        // Se ejecuta cuando ya existe una ruta
        .onChange(of: mapVM.route) { _, _ in
            mapVM.buildResultIfPossible(vehicle: vehicleType, fuel: fuelType, date: dateTime)
        }
        
      
       /* .onChange(of: mapVM.tollsOnRoute) { _, _ in
            mapVM.buildResultIfPossible(vehicle: vehicleType, fuel: fuelType, date: dateTime)
        }*/
        
        
        // Este onChange: solo se ejecuta cuando ya existen tolls en ruta y Calcula/ carga fees - usa swiftdata 24H
        .onChange(of: mapVM.tollsOnRoute) { _, tolls in
            guard !tolls.isEmpty else { return }

            feeVM.loadOrCalculateFees(
                tollsOnRoute: tolls,
                from: from,
                to: to,
                vehicle: vehicleType,
                fuel: fuelType,
                date: dateTime,
                modelContext: modelContext,
                storage: feeStorageVM
            )
        }


        
        .sheet(isPresented: $showDetailsSheet) {
            TollPassedListView(tolls: mapVM.tollsOnRoute)
                .presentationDetents([.medium, .large])
        }




    }
}


