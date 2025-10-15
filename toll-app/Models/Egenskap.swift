//
//  Egenskap.swift
//  toll-app
//
//  Created by Carolina Mera  on 14/10/2025.
//
import Foundation
import SwiftData

@Model
class Egenskap {
    var id: Int
    var navn: String
    var verdi: String?
    

    private enum CodingKeys: String, CodingKey {
        case id, navn, verdi
    }
    
    init(id: Int, navn : String, verdi: String?){
        self.id = id
        self.navn = navn
        self.verdi = verdi
    }
}
