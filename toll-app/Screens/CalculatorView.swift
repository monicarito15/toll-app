import SwiftUI

struct CalculatorView: View {
    @State private var from = ""
    @State private var to = ""
    @State private var showMap = false
    
    @FocusState private var focus: FormFieldFocus?
    
    @State private var selectedFuelType = "Gasoline"
    @State private var selectedVehicleType = "Car"
    @State private var selectedDateTime = Date()
    
    @State private var locationManager = LocationManager()
    
    let fuelTypes = ["Gasoline", "Diesel", "Electric", "Hybrid"]
    let vehicleTypes = ["Car", "Truck", "Motorcycle", "Bus"]
    
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Find tolls between locations")) {
                    ZStack (alignment: .trailing){
                        TextField ("From", text: $from)
                            .padding()
                            .onSubmit {
                                focus = .to
                            }
                        Button(action: {
                            locationManager.requestLocation()
                            
                        }) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                        }
                        .onReceive(locationManager.$currentAddress) { address in
                            if let address = address, !address.isEmpty {
                                from = address
                            }
                        }
                    }
                    
                    
                        .focused($focus, equals: .from)
                    TextField ("To", text: $to)
                        .padding()
                        .onSubmit {
                            focus = nil
                        }
                        .focused($focus, equals: .to)
                    DatePicker("Date and Time",
                               selection: $selectedDateTime,
                               displayedComponents: [.date, .hourAndMinute])
                }
               
                Section(header: Text("Vehicle Information")) {
                    Picker("Select Vehicle Type", selection: $selectedVehicleType) {
                        ForEach(vehicleTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Select Fuel Type", selection: $selectedFuelType) {
                        ForEach(fuelTypes, id: \.self) { type in
                            Text(type)
                        }
                        
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Button("Calculate route") {
                        showMap = true
                    
                    }
                    .sheet(isPresented: $showMap) {
                    MapView(
                    from: from,
                    to:to,
                    vehicleType: selectedVehicleType,
                    fuelType: selectedFuelType,
                    dateTime: selectedDateTime
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity) // para que ocupe todo el ancho
                    .background(Color.blue)   // el fondo que tú quieras
                    .foregroundColor(.white)  // color del texto
                    .cornerRadius(10)
                    
                    
                }
                
                    
                Section(header: Text("Nearby tolls")) {
                    SheetScrollView()
                    
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
        }
    }
    enum FormFieldFocus: Hashable {
        case from
        case to
    }
}
