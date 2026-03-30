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
    let fromCoordinate: CLLocationCoordinate2D?
    let toCoordinate: CLLocationCoordinate2D?
    let vehicleType: VehicleType
    let fuelType: FuelType
    let dateTime: Date
    let hasAutopass: Bool
    
    
    // ahora usamos el ViewModel, que contiene toda la lógica de ubicación, rutas y tolls
    
    @ObservedObject var mapVM : MapViewModel
    @StateObject private var tollStorageVM = TollStorageViewModel()
    @Environment(\.modelContext) private var modelContext

    
    @StateObject private var feeVM = FeeViewModel()
    @StateObject private var feeStorageVM = FeeStorageViewModel()
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    @State private var showDetailsSheet = false
    @State private var selectedToll: Vegobjekt?

   
    var body: some View {
        VStack {
            ZStack {
                Map(position: $cameraPosition) {
                    
                    // user location
                    if let userLocation = mapVM.userLocation {
                        // Center map on user location
                        Marker("My location", coordinate: userLocation)
                    }

                    ForEach(mapVM.tollsOnRoute) { vegobjekt in
                        if let coordinate = vegobjekt.lokasjon?.coordinates {
                            Annotation("", coordinate: coordinate) {
                                Button {
                                    selectedToll = vegobjekt
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 32, height: 32)
                                            .shadow(color: .black.opacity(0.3), radius: 3)
                                        
                                        Image(systemName: "norwegiankronesign")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
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
                
                // UI: barrita arriba (Solo cuando hay resultado)
                if mapVM.hasResult {
                    VStack {
                        TollSummaryBar(
                            tollCount: feeVM.tollCharges.isEmpty ? mapVM.tollsOnRoute.count : feeVM.tollCharges.count,
                            total: feeVM.totalPrice,
                            isEstimated: feeVM.isEstimatedPrice,
                            vehicleType: vehicleType,
                            fuelType: fuelType,
                            hasAutopass: hasAutopass,
                            originCoordinate: mapVM.originCoordinate,
                            destinationCoordinate: mapVM.destinationCoordinate,
                            fromAddress: from,
                            toAddress: to,
                            route: mapVM.route
                        ) {
                            showDetailsSheet = true
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                }
                
                // Botón flotante de navegación (abajo a la derecha)
                if mapVM.hasResult {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            NavigationFloatingButton(
                                originCoordinate: mapVM.originCoordinate,
                                destinationCoordinate: mapVM.destinationCoordinate,
                                fromAddress: from,
                                toAddress: to
                            )
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Toll detail popup
                if let toll = selectedToll {
                    VStack {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Toll: \(toll.displayName)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button {
                                    selectedToll = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if let location = toll.location {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(location)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: selectedToll?.id)
                }
                
            }
            .animation(.easeInOut, value: mapVM.hasResult)
        }
            

        
        .onAppear {
            //Cuando la vista aparece, se actualiza la ubicación del usuario
            mapVM.updateUserLocation()
            
            // Si hay direcciones válidas, calcula la ruta entre `from` y `to`
            Task { @MainActor in
                await mapVM.getDirectionsFromAddresses(
                    fromAddress: from,
                    toAddress: to,
                    fromCoordinate: fromCoordinate,
                    toCoordinate: toCoordinate
                )
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
        
      
        
        
        // Este onChange: solo se ejecuta cuando ya existen tolls en ruta y Calcula/ carga fees - usa swiftdata 24H
        .onChange(of: mapVM.tollsOnRoute) { _, tolls in
            guard !tolls.isEmpty else { return }
            
            // Configure autopass before calling API
            feeVM.hasAutoPassAgreement = hasAutopass

            // FeeViewModel handles everything: cache, API call, fallback
            feeVM.loadOrCalculateFees(
                tollsOnRoute: tolls,
                from: from,
                to: to,
                vehicle: vehicleType,
                fuel: fuelType,
                date: dateTime,
                modelContext: modelContext,
                storage: feeStorageVM,
                originCoordinate: mapVM.originCoordinate,
                destinationCoordinate: mapVM.destinationCoordinate
            )
        }


        
        .sheet(isPresented: $showDetailsSheet) {
            TollPassedListView(
                tollCharges: feeVM.tollCharges,
                route: mapVM.route,
                fromAddress: from,
                toAddress: to
            )
                .presentationDetents([.medium, .large])
        }




    }
}


