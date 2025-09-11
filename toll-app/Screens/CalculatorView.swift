import SwiftUI

struct CalculatorView: View {
    @State private var from = ""
    @State private var to = ""
    
    @FocusState private var focus: FormFieldFocus?
    
    @State private var selectedfuelType = "Gasoline"
    @State private var selectedVehicleType = "Car"
    @State private var selectedDateTime = Date()
    
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
              
                
            }
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
