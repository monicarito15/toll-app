/*
 import SwiftUI
 import MapKit
 
 struct TravelView: View {
 
 @Binding var showSheet: Bool
 @Binding var currentDetent : PresentationDetent
 
 @StateObject private var vm = MapViewModel()
 
 @State private var from = ""
 @State private var to = ""
 
 var body: some View {
 MapView(
 from: "Start Location",
 to: "End Location",
 vehicleType: "Car",
 fuelType: "Gasoline",
 dateTime: Date(),
 mapViewModel: vm
 )
 
 .sheet(isPresented: $showSheet) {
 VStack {
 CalculatorView (currentDetent: $currentDetent) {
 newFrom, newTo  in
 from = newFrom
 to = newTo
 
 Task {@MainActor in
 await vm.getDirectionsFromAddresses(fromAddress: from, toAddress: to)}
 }
 }
 .presentationDetents([.medium, .large], selection: $currentDetent)
 .onAppear {
 currentDetent = .medium // Asegura que el sheet siempre se abra medium
 }
 }
 }
 
 }
 
 */
