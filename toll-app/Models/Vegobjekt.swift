//
//  Vegobjekt.swift
//  toll-app
//
//  Created by Carolina Mera  on 12/09/2025.
//Data model for Vegobjekt API response

import Foundation
import CoreLocation
import ArcGIS
import SwiftData
 
 @Model
class Vegobjekt: Identifiable,Codable {
    @Attribute(.unique) var id: Int
    
    var href: String
    @Relationship(deleteRule: .cascade)
    var egenskaper: [Egenskap]
    var lokasjon: Lokasjon?
    
    init(id: Int, href: String, egenskaper: [Egenskap], lokasjon: Lokasjon) {
        self.id = id
        self.href = href
        self.egenskaper = egenskaper
        self.lokasjon = lokasjon
    }
    
    enum CodingKeys: String , CodingKey {
        case id, href, egenskaper, lokasjon
    }
    
    required init(from decoder: any Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         self.id = try container.decode(Int.self, forKey: .id)
         self.href = try container.decode(String.self, forKey: .href)
         self.egenskaper = try container.decode([Egenskap].self, forKey: .egenskaper)
         self.lokasjon = try? container.decode(Lokasjon.self, forKey: .lokasjon)
        
    }
    
    func encode(to encoder: Encoder ) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(href, forKey: .href)
        try container.encode(egenskaper, forKey: .egenskaper)
        try container.encode(lokasjon, forKey: .lokasjon)
    }
}
 







