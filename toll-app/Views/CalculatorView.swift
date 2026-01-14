import SwiftUI

struct CalculatorView: View {
    @State private var from = ""
    @State private var to = ""
    @State private var showMap = false
    
    @State private var showToDirections = false
    @State private var showFromDirections = false
    @State private var shouldApplyLocationToFrom = true

    @Binding var currentDetent: PresentationDetent
    
    @Environment(\.dismiss) private var dismiss
       
    
    @FocusState private var focus: FormFieldFocus?
    
    @State private var selectedFuelType : FuelType = .gas
    @State private var selectedVehicleType : VehicleType = .car
    @State private var selectedDateTime = Date()
    
    
    
    @StateObject private var locationManager = LocationManager()
    
    let fuelTypes :[FuelType] = [.gas, .electric]
    let vehicleTypes : [VehicleType] = [.car, .motorcycle]
    
    // Callback: le manda from/to al mapa (vista padre) para calcular la ruta
    let onCalculate: (_ _from: String, _ _to: String, _ _vehicle: VehicleType, _ fuel:FuelType, _ _date: Date) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Find tolls between locations")) {
                        
                       // FromDirectionView
                        HStack {
                            //cuando el usuario quiere buscar manual, abrimos el buscador, y prevenimos que el GPS vuelva a pisar "from"
                            Button {
                                showFromDirections = true
                                shouldApplyLocationToFrom = false
                                
                            } label: {
                                HStack {
                                    Text(from.isEmpty ? "From" : from)
                                        .foregroundStyle(from.isEmpty ? .gray : .primary)
                                    
                                    Spacer()
                                    
                                }
                                .padding()
                                
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                // Debug: confirma que el tap sí está pasando
                                print("Location icon tapped")
                                
                                shouldApplyLocationToFrom = true

                                // Si no hay permisos todavía, pide permisos
                                // (esto evita que requestLocation falle sin darte nada)
                                if locationManager.authorizationStatus == .notDetermined {
                                    locationManager.requestAuthorization()
                                    return
                                }

                                // Si está denegado/restringido, no va a funcionar
                                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                                    print("Location permission denied/restricted")
                                    return
                                }

                                // Si todo ok, pide una ubicación
                                locationManager.requestLocation()

                            } label: {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                            }
                            

                            .buttonStyle(.plain)
                        }
                        .onReceive(locationManager.$currentAddress) { address in
                            guard let address, !address.isEmpty else {
                                return }
                            print("onReceive currentAddress:", address)
                            print("shouldApplyLocationToFrom:", shouldApplyLocationToFrom)
                            
                            if shouldApplyLocationToFrom {
                                from = address
                                
                                shouldApplyLocationToFrom = false
                            }
                        }
                                

                            
                    .focused($focus, equals: .from)
                    
                    
                    // ToDirectionsView
                    Button(action: {
                        showToDirections = true
                    }) {
                        HStack {
                            Text(to.isEmpty ? "To" : to)
                           
                            .foregroundColor(to.isEmpty ? .gray : .primary)
                                
                            }
                            .padding()
                        }
                    
                    .focused($focus, equals: .to)
                    
                    
                    
                    DatePicker("Date and Time",
                               selection: $selectedDateTime,
                               displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Vehicle Information")) {
                    Picker("Select Vehicle Type", selection: $selectedVehicleType) {
                        ForEach(vehicleTypes) { type in
                                Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Select Fuel Type", selection: $selectedFuelType) {
                        ForEach(fuelTypes) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                        
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    
                    Button("Calculate route") {
                        let fromTrim = from.trimmingCharacters(in: .whitespacesAndNewlines)
                        let toTrim = to.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard !toTrim.isEmpty else { return }
                        
                        onCalculate(fromTrim, toTrim, selectedVehicleType, selectedFuelType, selectedDateTime) //manda los datos al map
                        dismiss()
                        
                        
                    }

                    
                    .padding()
                    .frame(maxWidth: .infinity) // para que ocupe todo el ancho
                    .background(Color.blue)   // el fondo que tú quieras
                    .foregroundColor(.white)  // color del texto
                    .cornerRadius(10)
                    
                    
                }
                
                
                Section(header: Text("Nearby tolls")) {
                    NearbyTolls()
                    
                }
                
            
            } // Form
            
            
    
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Calculate Toll")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
        }
        
        .onAppear {
            focus = .from
            shouldApplyLocationToFrom = true
            locationManager.requestLocation()
        }
        
        
        
        .sheet(isPresented: $showToDirections){
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
