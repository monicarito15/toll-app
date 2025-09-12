/*
 import Foundation
import CoreLocation
 
 struct TollResponse: Decodable {
     let objekter: [Toll]
 }
 
 struct Toll: Decodable, Identifiable {
     let id: Int
     let navn: String
     let coordinate: CLLocationCoordinate2D
 
 
 init(from decoder: Decoder) throws {
     let container = try decoder.container(keyedBy: CodingKeys.self)
     id = try container.decode(Int.self, forKey: .id)
     
     // Extract name from egenskaper
     let egenskaper = try container.decode([Egenskap].self, forKey: .egenskaper)
     if let nameProp = egenskaper.first(where: { $0.navn == "Navn bomstasjon" }) {
         navn = nameProp.verdi
         
     } else {
         navn = "Desconocido"
     }
     // Extract coordinates from lokasjon.geometri.wkt
     let lokasjon = try container.nestedContainer(keyedBy: LokasjonKeys.self, forKey: .lokasjon)
     let geometri = try lokasjon.nestedContainer(keyedBy: GeometriKeys.self, forKey: .geometri)
     let wkt = try geometri.decode(String.self, forKey: .wkt)
     coordinate = Toll.coordinateFromWKT(wkt)
     }
     
 enum CodingKeys: String, CodingKey {
     case id
     case egenskaper
     case lokasjon
    }
 enum LokasjonKeys: String, CodingKey {
     case geometri
    }
 enum GeometriKeys: String, CodingKey {
     case wkt
    }
 
 static func coordinateFromWKT(_ wkt: String) -> CLLocationCoordinate2D {
 // Example: "POINT Z (-32178.466 6737228.032 31.684)"
     let pattern = #"POINT Z \((-?\d+\.\d+) (-?\d+\.\d+) [\d\.]+\)"#
     if let regex = try? NSRegularExpression(pattern: pattern),
     let match = regex.firstMatch(in: wkt, range: NSRange(wkt.startIndex..., in: wkt)),
     match.numberOfRanges >= 3,
     let lonRange = Range(match.range(at: 1), in: wkt),
     let latRange = Range(match.range(at: 2), in: wkt),
     let lon = Double(wkt[lonRange]),
     let lat = Double(wkt[latRange]) {
     // Note: WKT is usually (X Y), which may be (longitude latitude) or (easting northing)
 // You may need to convert to lat/lon if the SRID is not WGS84 (4326)
    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
     }
     return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
 }
 
 struct Egenskap: Decodable {
     let navn: String
     let verdi: String
 }

 
 */
 
