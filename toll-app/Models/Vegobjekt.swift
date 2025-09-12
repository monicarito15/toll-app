//
//  Vegobjekt.swift
//  toll-app
//
//  Created by Carolina Mera  on 12/09/2025.
//
import Foundation
import CoreLocation
 
 struct VegokbjektResponse: Decodable {
     let objekter: [Vegobjekt]
 }


struct Vegobjekt: Identifiable, Decodable {
    let id: Int
    let href: String
    let egenskaper: [Egenskap]
    let lokasjon: Lokasjon
}


struct Egenskap: Decodable {
    let id: Int
    let navn: String
    let verdi: Int
}

struct Lokasjon: Decodable {
    let geometri: Geometri
    
    var coordinates: CLLocationCoordinate2D? {
            let wkt = geometri.wkt
            guard wkt.hasPrefix("POINT"),
                  let start = wkt.firstIndex(of: "("),
                  let end = wkt.firstIndex(of: ")") else { return nil }
            let coordsString = wkt[wkt.index(after: start)..<end]
            let components = coordsString.split(separator: " ")
            guard components.count == 2,
                  let longitude = Double(components[0]),
                  let latitude = Double(components[1]) else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }


struct Geometri: Decodable {
    let wkt: String
    let srid: Int
}




