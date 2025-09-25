//
//  ToDirections.swift
//  toll-app
//
//  Created by Carolina Mera  on 24/09/2025.
//
// This is a view for searching directions with a search bar and a title. Have sheet presentation detents for medium and large sizes. Activate with ToDirections button.

import SwiftUI


struct ToDirectionsView : View {

    @Binding var searchText : String
    @Binding var currentDetent: PresentationDetent
    
    var body: some View {
    
        NavigationView {
            
            VStack (alignment: .leading){
              
                    HStack {
                        
                        TextField("Search", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                Spacer()
                    
                }
                
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Directions")
                            .font(.system(size:30, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
            }
        
        .presentationDetents([.medium, .large], selection: $currentDetent) // usa el mismo binding
    }
}



