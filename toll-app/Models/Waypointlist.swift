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
}

struct BkFeesRequest: Codable {
    let startTime: String          
    let waypoints: [Waypointlist]
    let autopassAgreement: Bool    // si el API lo soporta (si no, lo mapeamos luego)
    let vehicleType: String
    let fuelType: String
}

struct BkFeesResponse: Codable {
    let total: Double?
    // y un array de “passages/fees” según el API
}
