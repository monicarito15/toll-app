//
//  Vegobjekt.swift
//  toll-app
//
//  Created by Carolina Mera  on 12/09/2025.
//Data model for Vegobjekt API response

import Foundation
import CoreLocation
import ArcGIS
 
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
        // Accept both POINT (x y) and POINT Z (x y z)
        guard components.count >= 2,
              let easting = Double(components[0]),
              let northing = Double(components[1]) else { return nil }
        // Use Esri SDK to convert UTM to WGS84
        return convertUTMToWGS84(easting: easting, northing: northing)
    }
    
}


struct Geometri: Decodable {
    let wkt: String
    let srid: Int
}

import ArcGIS
import CoreLocation

import ArcGIS
import CoreLocation

func convertUTMToWGS84(easting: Double, northing: Double) -> CLLocationCoordinate2D? {
    // SRID 5973 = EUREF89 / UTM zone 32N
    guard let wkid = WKID(5973) else { return nil }
    let utmSpatialReference = SpatialReference(wkid: wkid)
    let utmPoint = Point(x: easting, y: northing, spatialReference: utmSpatialReference)
    let wgs84SpatialReference = SpatialReference.wgs84
    
    if let wgs84Point = GeometryEngine.project(utmPoint, into: wgs84SpatialReference) {
        return CLLocationCoordinate2D(latitude: wgs84Point.y, longitude: wgs84Point.x)
    }
    return nil
}





