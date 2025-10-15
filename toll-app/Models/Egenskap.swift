//
//  Egenskap.swift
//  toll-app
//
//  Created by Carolina Mera  on 14/10/2025.
//
import Foundation
import SwiftData

@Model
class Egenskap: Codable {
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
    
    //Decoding Personalizado porque 'verdi' puede ser String, Int o Double
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            navn = try container.decode(String.self, forKey: .navn)

            // Aquí manejamos los 3 casos
            if let verdiString = try? container.decode(String.self, forKey: .verdi) {
                verdi = verdiString
            } else if let verdiInt = try? container.decode(Int.self, forKey: .verdi) {
                verdi = String(verdiInt)
            } else if let verdiDouble = try? container.decode(Double.self, forKey: .verdi) {
                verdi = String(verdiDouble)
            } else {
                verdi = nil
            }
        }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(navn, forKey: .navn)
        try container.encodeIfPresent(verdi, forKey: .verdi)

    }
}
