import SwiftUI

struct CalculatorView: View {
    @State private var from = ""
    @State private var to = ""
    
    @FocusState private var focus: FormFieldFocus?
    
    @State private var selectedfuelType = "Gasoline"
    @State private var selectedVehicleType = "Car"
    
    let fuelTypes = ["Gasoline", "Diesel", "Electric", "Hybrid"]
    let vehicleTypes = ["Car", "Truck", "Motorcycle", "Bus"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Find tolls between locations")) {
                    TextField ("From", text: $from)
                        .padding()
                        .onSubmit {
                            focus = .to
                        }
                        .focused($focus, equals: .from)
                    TextField ("To", text: $to)
                        .padding()
                        .onSubmit {
                            focus = nil
                        }
                        .focused($focus, equals: .to)
                }
                
                Section(header: Text("Vehicle Type")) {
                    Picker("Select Vehicle Type", selection: $selectedVehicleType) {
                        ForEach(vehicleTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                Section(header: Text("Fuel Type")) {
                    Picker("Select Fuel Type", selection: $selectedfuelType) {
                        ForEach(fuelTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                Section(header: Text("Nearby tolls")) {
                    SheetScrollView()
                }
                Section(header: Text("Favorite routes")) {
                    TextField ("Add favorite route", text: .constant(""))
                        .padding()
                }
            }
            .navigationTitle("Calculate Toll")
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
