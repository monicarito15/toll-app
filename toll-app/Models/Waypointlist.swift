//
//  BkWaypoint.swift
//  toll-app
//
//  Created by Carolina Mera  on 16/01/2026.
//

import Foundation
import CoreLocation

struct Waypointlist: Codable {
    let latitude: Double
    let longitude: Double
    let time: Int? // seconds from start
    
    enum CodingKeys: String, CodingKey {
        case latitude = "Latitude"
        case longitude = "Longitude"
        case time = "Time"
        
    }
}


struct WaypointRequest: Codable {
    let waypoints: [Waypointlist]
    let dato_yyyymmdd: String
    let tidspunkt_hhmm: String
    let bilsize: Int // car, truck, moto etc.
    let litenbiltype: Int// fuel type for small vehicles
    //let Storbiltype: Int // fuel type for large vehicles
    //let billengdeunder: String
    let retur: Int
    let tidsreferanser: Int?
    
    enum codingKeys: String, CodingKey {
        case waypoints = "Waypoints"
        case dato_yyyymmdd = "Dato_yyyymmdd"
        case tidspunkt_hhmm = "Tidspunkt_hhmm"
        case bilsize = "Bilsize"
        case litenbiltype = "Litenbiltype"
        //case Storbiltype = "Storbiltype"
        //case billengdeunder = "Billengdeunder"
        case retur = "Retur"
        case tidsreferanser = "Tidsreferanser"
        
    }
}

struct WaypointResponse: Codable {
    let tur: [Trip]?
    
    enum CodingKeys: String, CodingKey {
     case tur = "Tur"
    }
    
    struct Trip: Codable {
        let totalPrice: Double?
        let totalWithAutopass: Double?
        
        enum CodingKeys: String, CodingKey {
            case totalPrice = "Totalprice"
            case totalWithAutopass = "TotalwithAutopass"
        }
    }
}
