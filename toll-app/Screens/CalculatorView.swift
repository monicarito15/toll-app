import SwiftUI

struct CalculatorView: View {
    @State private var textInput = ""
    @State private var textInput2 = ""

    @FocusState private var focus: FormFieldFocus?
    
    var body: some View {
        Text("Calculate Toll")
            .font(.title)
            .padding()
        Spacer()
            VStack{
                TextField ("From", text: $textInput)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit{
                        print(textInput)
                        focus = .to

                    }
                    .focused($focus, equals: .from)
                    
                
                TextField ("To", text: $textInput2)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit{
                        print(textInput2)
                        focus = nil //cierra el teclado
                    }
                    .focused($focus, equals: .to)
        }
            .onAppear{
                focus = .from
                
            }
    }
    
    enum FormFieldFocus: Hashable {
        case from
        case to
        
        
    }
}

