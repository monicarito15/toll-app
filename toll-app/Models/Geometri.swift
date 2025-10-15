//
//  Geometri.swift
//  toll-app
//
//  Created by Carolina Mera  on 14/10/2025.
//

import Foundation
import SwiftData
import CoreLocation
import ArcGIS

@Model
class Geometri: Codable {
    var wkt: String
    var srid: Int
    
    init(wkt: String, srid: Int) {
        self.wkt = wkt
        self.srid = srid
    }
    
    enum CodingKeys: String, CodingKey {
        case wkt, srid
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wkt = try container.decode(String.self,forKey: .wkt)
        srid = try container.decode(Int.self, forKey: .srid)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wkt, forKey: .wkt)
        try container.encode(srid, forKey: .srid)
    }
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
