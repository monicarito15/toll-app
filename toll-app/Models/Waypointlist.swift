////
////  BkWaypoint.swift
////  toll-app
////
////  Created by Carolina Mera  on 16/01/2026.
////
//
//import Foundation
//import CoreLocation
//
//struct Waypointlist: Codable {
//    let latitude: Double
//    let longitude: Double
//    let time: Int? // seconds from start
//    
//    enum CodingKeys: String, CodingKey {
//        case latitude = "Latitude"
//        case longitude = "Longitude"
//        case time = "Time"
//        
//    }
//}
//
//
//struct WaypointRequest: Codable {
//    let fra: Waypointlist
//    let til: Waypointlist
//    let dato_yyyymmdd: String
//    let tidspunkt_hhmm: String
//    let bilsize: Int // car, truck, moto.
//    let litenbiltype: Int // fuel type for small vehicles
//    let retur: Int
//    let tidsreferanser: Int?
//
//    enum CodingKeys: String, CodingKey {
//        case fra = "Fra"
//        case til = "Til"
//        case dato_yyyymmdd = "Dato_yyyymmdd"
//        case tidspunkt_hhmm = "Tidspunkt_hhmm"
//        case bilsize = "Bilsize"
//        case litenbiltype = "Litenbiltype"
//        case retur = "Retur"
//        case tidsreferanser = "Tidsreferanser"
//    }
//}
//
//struct WaypointResponse: Codable {
//    let tur: [Trip]?
//    
//    enum CodingKeys: String, CodingKey {
//     case tur = "Tur"
//    }
//    
//    struct TollFee: Codable {
//        let price: Double?
//        let discountedPrice: Double?
//        
//        enum CodingKeys: String, CodingKey {
//            case price = "Pris"
//            case discountedPrice = "PrisRabbattert"
//        }
//    }
//    
//    struct TollStation: Codable {
//        let name: String?
//        let fees: [TollFee]?
//        let latitude: String?
//        let longitude: String?
//        
//        enum CodingKeys: String, CodingKey {
//            case name = "Navn"
//            case fees = "Avgifter"
//            case latitude = "Latitude"
//            case longitude = "Longitude"
//        }
//    }
//    
//    struct Trip: Codable {
//        let totalPrice: Double?
//        let totalWithAutopass: Double?
//        let tollStations: [TollStation]?
//        
//        enum CodingKeys: String, CodingKey {
//            case totalPrice = "Kostnad"
//            case totalWithAutopass = "Rabattert"
//            case tollStations = "AvgiftsPunkter"
//        }
//    }
//}
//
//
//extension WaypointResponse {
//    // Gets the correct price based on autopass status
//    func getPrice(hasAutopass: Bool) -> Double? {
//        guard let trip = tur?.first else { return nil }
//        
//        if hasAutopass {
//            return trip.totalWithAutopass ?? trip.totalPrice
//        } else {
//            return trip.totalPrice
//        }
//    }
//    
//    // Gets both prices for debugging
//    func getPrices() -> (withoutAutopass: Double?, withAutopass: Double?) {
//        guard let trip = tur?.first else { return (nil, nil) }
//        return (trip.totalPrice, trip.totalWithAutopass)
//    }
//    
//    // Gets individual toll stations with prices from AvgiftsPunkter → Avgifter
//    // Uses only the first trip (trips are alternative routes, not segments)
//    func getTollCharges(hasAutopass: Bool) -> [TollCharge] {
//        guard let stations = tur?.first?.tollStations, !stations.isEmpty else {
//            #if DEBUG
//            print("getTollCharges: No toll stations found in first trip")
//            print("   tur count: \(tur?.count ?? 0)")
//            print("   first trip tollStations: \(tur?.first?.tollStations?.count ?? -1)")
//            #endif
//            return []
//        }
//        
//        var charges: [TollCharge] = []
//        
//        for (index, station) in stations.enumerated() {
//            guard let fee = station.fees?.first else {
//                #if DEBUG
//                print("Skipping station '\(station.name ?? "Unknown")' - no fee data (fees: \(station.fees?.count ?? -1))")
//                #endif
//                continue
//            }
//            
//            let price = hasAutopass ? (fee.discountedPrice ?? fee.price) : fee.price
//            
//            guard let finalPrice = price, finalPrice > 0 else {
//                #if DEBUG
//                print("Skipping station '\(station.name ?? "Unknown")' - price is zero or nil")
//                #endif
//                continue
//            }
//            
//            charges.append(TollCharge(
//                id: "\(index)-\(station.name ?? "unknown")",
//                toll: station.name ?? "Unknown",
//                price: finalPrice,
//                latitude: Double(station.latitude ?? ""),
//                longitude: Double(station.longitude ?? "")
//            ))
//        }
//        
//        #if DEBUG
//        print("getTollCharges: Found \(charges.count) stations with prices out of \(stations.count)")
//        #endif
//        
//        return charges
//    }
//    
//    // Gets station names from first trip only
//    func getTollStationNames() -> [String] {
//        guard let stations = tur?.first?.tollStations else { return [] }
//        return stations.compactMap { $0.name }
//    }
//}
//
