//
//  ToDirections.swift
//  toll-app
//
//  Created by Carolina Mera  on 24/09/2025.
//
import SwiftUI


struct ToDirectionsView : View {

    @Binding var searchText : String
    @Binding var currentDetent: PresentationDetent
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .navigationBarTitle("To Directions")
            }
        }
        .presentationDetents([.medium, .large], selection: $currentDetent) // usa el mismo binding
    }
}

