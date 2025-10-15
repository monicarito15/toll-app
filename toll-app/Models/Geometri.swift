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
class Geometri {
    var wkt: String
    var srid: Int
    
    init(wkt: String, srid: Int) {
        self.wkt = wkt
        self.srid = srid
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
