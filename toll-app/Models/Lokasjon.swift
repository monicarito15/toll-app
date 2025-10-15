//
//  Lokasjon.swift
//  toll-app
//
//  Created by Carolina Mera  on 14/10/2025.
//
import Foundation
import SwiftData
import CoreLocation
import ArcGIS

@Model
class Lokasjon {
    var geometri: Geometri
    
    init(geometri: Geometri) {
        self.geometri = geometri
    }
    
    var coordinates: CLLocationCoordinate2D? {
        let wkt = geometri.wkt
        guard wkt.hasPrefix("POINT"),
              let start = wkt.firstIndex(of: "("),
              let end = wkt.firstIndex(of: ")") else { return nil }
        let coordsString = wkt[wkt.index(after: start)..<end]
        let components = coordsString.split(separator: " ")
        // Accept both POINT (x y) and POINT Z (x y z)
        guard components.count >= 2,
              let easting = Double(components[0]),
              let northing = Double(components[1]) else { return nil }
        // Use Esri SDK to convert UTM to WGS84
        //return convertUTMToWGS84(easting: easting, northing: northing)
        
        if let coord = convertUTMToWGS84(easting: easting, northing: northing) {
                    /*print("Converted UTM (\(easting), \(northing)) → WGS84 (\(coord.latitude), \(coord.longitude))")*/
                    return coord
                }
                return nil
    }
    
}
