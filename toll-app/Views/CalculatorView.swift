import SwiftUI
import CoreLocation
import SwiftData
import _LocationEssentials

struct CalculatorView: View {
    
    @ObservedObject var mapVM: MapViewModel
    
    @Binding var from: String
    @Binding var to: String
    @State private var showMap = false
    
    @State private var showToDirections = false
    @State var showFromDirections = false
    @State private var showHistory = false
    @State private var shouldApplyLocationToFrom = true
    @State private var isFromCurrentLocation: Bool = false
    @State private var isToCurrentLocation: Bool = false
    @Binding var autopassOn: Bool
    
    @Binding var currentDetent: PresentationDetent
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @FocusState private var focus: FormFieldFocus?
    
    @Binding var selectedFuelType: FuelType
    @Binding var selectedVehicleType: VehicleType
    @Binding var selectedDateTime: Date
    
    @StateObject private var locationManager = LocationManager()
    
    
    let fuelTypes: [FuelType] = [.gas, .electric]
    let vehicleTypes: [VehicleType] = [.car, .motorcycle]

    
    
    // Callback: le avisa al padre que calcule la ruta (los valores ya están compartidos via Binding)
    let onCalculate: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    routeAndTimeSection
                    
                    // Rush Hour Warning (if applicable)
                    if selectedDateTime.isRushHour() {
                        RushHourWarningView(date: selectedDateTime)
                    }
                    
                    vehicleDetailsSection
                    calculateButton
                    nearbyTollsSection
                }
                .padding(.vertical, 20)
            }
            .background(
                Color(colorScheme == .dark ? .black : .systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Calculate Toll")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                
            }
        }
        .onAppear {
            focus = .from
            if from.isEmpty {
                shouldApplyLocationToFrom = true
                isFromCurrentLocation = true
                locationManager.requestLocation()
            }
            
            else {
                shouldApplyLocationToFrom = false
                isFromCurrentLocation = false
            }
            Task {
                await mapVM.fetchTolls()
                mapVM.updateUserLocation()
            }
        }
        .sheet(isPresented: $showToDirections) {
            ToDirectionsView(
                searchText: $to, 
                currentDetent: $currentDetent, 
                isFromCurrentLocation: $isToCurrentLocation
            )
                .presentationDetents([.medium, .large], selection: $currentDetent)
        }
        .sheet(isPresented: $showFromDirections) {
            FromDirectionsView(searchText: $from, currentDetent: $currentDetent, isFromCurrentLocation: $isFromCurrentLocation)
        }
        .onDisappear {
            shouldApplyLocationToFrom = false
        }
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.white)
    }
    
    
    // Route & Time Section
    private var routeAndTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ROUTE & TIME")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                // FROM field con swap button
                ZStack(alignment: .trailing) {
                    fromField
                    
                    swapButton
                        .padding(.trailing, 12)
                }
                
                Divider()
                    .padding(.leading, 56)
                
                toField
                
                Divider()
                    .padding(.leading, 56)
                
                datePickerField
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }
    
    private var swapButton: some View {
        Button {
            swapFromTo()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.blue))
                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
        
        private func swapFromTo() {
            // Intercambiar textos
            let tempFrom = from
            from = to
            to = tempFrom
            
            // Intercambiar estados de ubicación actual
            let tempIsFromCurrentLocation = isFromCurrentLocation
            isFromCurrentLocation = isToCurrentLocation
            isToCurrentLocation = tempIsFromCurrentLocation
            
            // Evita que la LocationManager sobrescriba from inmediatamente
            shouldApplyLocationToFrom = false
            
            focus = .to
        }
    
    
    private var fromField: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.green)
                .frame(width: 24)
            
            Button {
                showFromDirections = true
                // Important: When user manually selects address, stop auto-location
                shouldApplyLocationToFrom = false
                isFromCurrentLocation = false
                
            } label: {
                HStack {
                    if isFromCurrentLocation {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                        Text("Your location")
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                    } else {
                        
                        Text(from.isEmpty ? "From" : from)
                            .foregroundStyle(from.isEmpty ? .tertiary : .primary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
//            Button {
//                // El usuario pide usar su ubicación y mostramos "Your location" inmediatamente
//                shouldApplyLocationToFrom = false
//                isFromCurrentLocation = false
//                
//                if locationManager.authorizationStatus == .notDetermined {
//                    locationManager.requestAuthorization()
//                    return
//                }
//                
//                if locationManager.authorizationStatus == .denied ||
//                    locationManager.authorizationStatus == .restricted {
//                    print("Location permission denied/restricted")
//                    return
//                }
//                
//                locationManager.requestLocation()
//            } label: {
//                HStack {
//                    Image(systemName: "location.fill")
//                        .font(.system(size: 16))
//                        .foregroundStyle(.blue)
//                        .frame(width: 32, height: 32)
//                        .background(Color.blue.opacity(0.1), in: Circle())
//                }
//            }
//            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .focused($focus, equals: .from)
        .onReceive(locationManager.$currentAddress) { address in
            guard let address, !address.isEmpty,
                  shouldApplyLocationToFrom else { return }
            from = address
            shouldApplyLocationToFrom = false
        }
    }
    
    private var toField: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.red)
                .frame(width: 24)
            
            Button {
                showToDirections = true
            } label: {
                HStack {
                    if isToCurrentLocation {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                        Text("Your location")
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                    } else {
                        Text(to.isEmpty ? "To" : to)
                            .foregroundStyle(to.isEmpty ? .tertiary : .primary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .focused($focus, equals: .to)
    }
    
    
    
    
    private var datePickerField: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            DatePicker(
                "Date and Time",
                selection: $selectedDateTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Vehicle Details Section
    private var vehicleDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VEHICLE DETAILS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                vehicleTypePicker
                
                Divider()
                    .padding(.leading, 56)
                
                fuelTypePicker
                
                Divider()
                    .padding(.leading, 56)
                
                autopassToggle
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }
    
    private var vehicleTypePicker: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedVehicleType == .car ? "car.fill" : "figure.walk")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text("Vehicle Type")
                .foregroundStyle(.primary)
            
            Spacer()
            
            Picker("Vehicle Type", selection: $selectedVehicleType) {
                ForEach(vehicleTypes) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
    
    private var fuelTypePicker: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedFuelType == .gas ? "fuelpump.fill" : "bolt.fill")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text("Fuel Type")
                .foregroundStyle(.primary)
            
            Spacer()
            
            Picker("Fuel Type", selection: $selectedFuelType) {
                ForEach(fuelTypes) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
    
    private var autopassToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(autopassOn ? .blue : .secondary)
                .frame(width: 24)
            
            Text("Autopass")
                .foregroundStyle(.primary)
            
            Spacer()
            
            Toggle("", isOn: $autopassOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
    
    // Calculate Button
    private var calculateButton: some View {
        Button {
            // Determinar la dirección "From" a usar
            let fromAddress: String
            if isFromCurrentLocation {
                // Si es ubicación actual, usar la dirección del locationManager
                fromAddress = locationManager.currentAddress ?? ""
            } else {
                fromAddress = from.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Determinar la dirección "To" a usar
            let toAddress: String
            if isToCurrentLocation {
                // Si es ubicación actual, usar la dirección del locationManager
                toAddress = locationManager.currentAddress ?? ""
            } else {
                toAddress = to.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            guard !toAddress.isEmpty else { return }
            
            // Debug: Print selected options
            print("CALCULATOR VIEW - User Selection:")
            print("   Vehicle Type: \(selectedVehicleType.rawValue)")
            print("   Fuel Type: \(selectedFuelType.rawValue)")
            print("   Autopass: \(autopassOn ? "ON" : "OFF")")
            print("   From: \(fromAddress) (isCurrentLocation: \(isFromCurrentLocation))")
            print("   To: \(toAddress) (isCurrentLocation: \(isToCurrentLocation))")
            print("   DateTime: \(selectedDateTime)")
            
            // Guardar en el historial
            saveToHistory(
                fromAddress: fromAddress,
                toAddress: toAddress,
                vehicleType: selectedVehicleType.rawValue,
                fuelType: selectedFuelType.rawValue,
                hasAutopass: autopassOn,
                dateTime: selectedDateTime
            )
            
            // Actualizar los bindings con las direcciones resueltas
            from = fromAddress
            to = toAddress
            
            onCalculate()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                Text("Calculate Route")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .disabled(to.isEmpty && !isToCurrentLocation)
        .opacity((to.isEmpty && !isToCurrentLocation) ? 0.5 : 1.0)
    }
    
// Nearby Tolls Section
    private var nearbyTollsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEARBY TOLLS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                NearbyTolls(mapVm: mapVM) { selectedToll in
                    handleTollSelection(selectedToll)
                }
            }
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }
    
    
    private func handleTollSelection(_ selectedToll: Vegobjekt) {
        guard let tollCoords = selectedToll.lokasjon?.coordinates else { return }
        
        let tollName = selectedToll.egenskaper.first(where: { $0.navn == "Navn bomstasjon" })?.verdi
            ?? selectedToll.egenskaper.first(where: { $0.navn == "Navn bompengeanlegg (fra CS)" })?.verdi
            ?? "Toll \(selectedToll.id)"
        
        let location = CLLocation(latitude: tollCoords.latitude, longitude: tollCoords.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            let tollAddress = placemarks?.first?.name ?? "\(tollCoords.latitude), \(tollCoords.longitude)"
            
            // Si FROM está vacío y no es "Your location", poner la ubicación del usuario
            if from.isEmpty && !isFromCurrentLocation {
                if let userLoc = mapVM.userLocation {
                    let userLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                    CLGeocoder().reverseGeocodeLocation(userLocation) { placemarks, _ in
                        let fromAddress = placemarks?.first?.name ?? locationManager.currentAddress ?? ""
                        from = fromAddress
                        isFromCurrentLocation = false
                    }
                }
            }
            
            // Siempre poner el toll en TO
            to = tollAddress
            isToCurrentLocation = false
        }
    }
    
    // Save to History
    private func saveToHistory(
        fromAddress: String,
        toAddress: String,
        vehicleType: String,
        fuelType: String,
        hasAutopass: Bool,
        dateTime: Date
    ) {
        let history = SearchHistoryItem(
            fromAddress: fromAddress,
            toAddress: toAddress,
            vehicleType: VehicleType(rawValue: vehicleType) ?? .car,
            fuelType: FuelType(rawValue: fuelType) ?? .gas,
            dateTime: dateTime,
            hasAutopass: hasAutopass
        )
        
        modelContext.insert(history)
        
        do {
            try modelContext.save()
            print("Route saved to history")
        } catch {
            print("Error saving route: \(error.localizedDescription)")
        }
    }
    
    enum FormFieldFocus: Hashable {
        case from
        case to
    }
}
