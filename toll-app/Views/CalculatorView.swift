import SwiftUI

struct CalculatorView: View {
    @State private var from = ""
    @State private var to = ""
    @State private var showMap = false
    
    @State private var showToDirections = false
    @State private var showFromDirections = false
    @State private var shouldApplyLocationToFrom = true
    @State private var autopassOn: Bool = false
    
    @Binding var currentDetent: PresentationDetent
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @FocusState private var focus: FormFieldFocus?
    
    @State private var selectedFuelType: FuelType = .gas
    @State private var selectedVehicleType: VehicleType = .car
    @State private var selectedDateTime = Date()
    
    @StateObject private var locationManager = LocationManager()
    
    let fuelTypes: [FuelType] = [.gas, .electric]
    let vehicleTypes: [VehicleType] = [.car, .motorcycle]

    
    // Callback: le manda from/to al mapa (vista padre) para calcular la ruta
    let onCalculate: (_ _from: String, _ _to: String, _ _vehicle: VehicleType, _ fuel: FuelType, _ _date: Date, _ _hasAutopass: Bool ) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Route & Time Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ROUTE & TIME")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // From Field
                            HStack(spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.green)
                                    .frame(width: 24)
                                
                                Button {
                                    showFromDirections = true
                                    shouldApplyLocationToFrom = false
                                } label: {
                                    HStack {
                                        Text(from.isEmpty ? "From" : from)
                                            .foregroundStyle(from.isEmpty ? .tertiary : .primary)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    shouldApplyLocationToFrom = true
                                    
                                    if locationManager.authorizationStatus == .notDetermined {
                                        locationManager.requestAuthorization()
                                        return
                                    }
                                    
                                    if locationManager.authorizationStatus == .denied ||
                                        locationManager.authorizationStatus == .restricted {
                                        print("Location permission denied/restricted")
                                        return
                                    }
                                    
                                    locationManager.requestLocation()
                                } label: {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.blue)
                                        .frame(width: 32, height: 32)
                                        .background(Color.blue.opacity(0.1), in: Circle())
                                }
                                .buttonStyle(.plain)
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
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // To Field
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                                    .frame(width: 24)
                                
                                Button {
                                    showToDirections = true
                                } label: {
                                    HStack {
                                        Text(to.isEmpty ? "To" : to)
                                            .foregroundStyle(to.isEmpty ? .tertiary : .primary)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                            .focused($focus, equals: .to)
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // Date Picker
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // MARK: - Vehicle Details Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VEHICLE DETAILS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Vehicle Type Picker
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
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // Fuel Type Picker
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
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // Autopass Toggle
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // MARK: - Calculate Button
                    Button {
                        let fromTrim = from.trimmingCharacters(in: .whitespacesAndNewlines)
                        let toTrim = to.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard !toTrim.isEmpty else { return }
                        
                        onCalculate(fromTrim, toTrim, selectedVehicleType, selectedFuelType, selectedDateTime,autopassOn)
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
                    .disabled(to.isEmpty)
                    .opacity(to.isEmpty ? 0.5 : 1.0)
                    
                    // MARK: - Nearby Tolls Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NEARBY TOLLS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            NearbyTolls()
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
            shouldApplyLocationToFrom = true
            locationManager.requestLocation()
        }
        .sheet(isPresented: $showToDirections) {
            ToDirectionsView(searchText: $to, currentDetent: $currentDetent)
                .presentationDetents([.medium, .large], selection: $currentDetent)
        }
        .sheet(isPresented: $showFromDirections) {
            FromDirectionsView(searchText: $from, currentDetent: $currentDetent)
        }
        .onDisappear {
            shouldApplyLocationToFrom = false
        }
    }
    
    enum FormFieldFocus: Hashable {
        case from
        case to
    }
}
