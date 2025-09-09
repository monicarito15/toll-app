//
//  SheetScrollView.swift
//  toll-app
//
//  Created by Carolina Mera  on 09/09/2025.
//

import SwiftUI

struct SheetScrollView: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing:10){
                ForEach(0..<5) { index in
                    Rectangle()
                        .frame(width: 200, height: 150)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(Text("\(index)").foregroundColor(.white))
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
}
                    
