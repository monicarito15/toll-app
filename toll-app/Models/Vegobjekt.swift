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
    let id: String
    let href: String
    let egenskaper: [Egenskap]
    let lokasjon: Lokasjon

    private enum CodingKeys: String, CodingKey {
        case id, href, egenskaper, lokasjon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id as String, Int, or Double
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else if let idDouble = try? container.decode(Double.self, forKey: .id) {
            id = String(idDouble)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "id is not String, Int, or Double")
        }
        href = try container.decode(String.self, forKey: .href)
        egenskaper = try container.decode([Egenskap].self, forKey: .egenskaper)
        lokasjon = try container.decode(Lokasjon.self, forKey: .lokasjon)
    }
}


struct Egenskap: Decodable {
    let id: String
    let navn: String
    let verdi: String

    private enum CodingKeys: String, CodingKey {
        case id, navn, verdi
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id as String, Int, or Double
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else if let idDouble = try? container.decode(Double.self, forKey: .id) {
            id = String(idDouble)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "id is not String, Int, or Double")
        }
        navn = try container.decode(String.self, forKey: .navn)
        // verdi as String, Int, or Double
        if let verdiString = try? container.decode(String.self, forKey: .verdi) {
            verdi = verdiString
        } else if let verdiInt = try? container.decode(Int.self, forKey: .verdi) {
            verdi = String(verdiInt)
        } else if let verdiDouble = try? container.decode(Double.self, forKey: .verdi) {
            verdi = String(verdiDouble)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .verdi, in: container, debugDescription: "verdi is not String, Int, or Double")
        }
    }
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
        //return convertUTMToWGS84(easting: easting, northing: northing)
        
        if let coord = convertUTMToWGS84(easting: easting, northing: northing) {
                    print("Converted UTM (\(easting), \(northing)) → WGS84 (\(coord.latitude), \(coord.longitude))")
                    return coord
                }
                return nil
    }
    
}


struct Geometri: Decodable {
    let wkt: String
    let srid: Int
}



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
