//
//  TollCharge.swift
//  toll-app
//
//  Created by Carolina Mera  on 16/01/2026.

// este model es solo para el precio para la UI

import Foundation

struct TollCharge: Codable, Identifiable {
    
    var id: String
    var toll: String
    var price: Double
}

