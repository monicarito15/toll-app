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
class Vegobjekt: Identifiable {
    @Attribute(.unique) var id: Int
    var href: String
    @Relationship(deleteRule: .cascade)
    var egenskaper: [Egenskap]
    var lokasjon: Lokasjon?
    
    init(id: Int, href: String, egenskaper: [Egenskap], lokasjon: Lokasjon?) {
        self.id = id
        self.href = href
        self.egenskaper = egenskaper
        self.lokasjon = lokasjon
    }
}
