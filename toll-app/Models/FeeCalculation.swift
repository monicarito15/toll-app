//
//  FeeCalculation.swift
//  toll-app
//
//  Created by Carolina Mera  on 16/01/2026.

// SwiftData Model for fees - asi como el vegobjekt

import Foundation
import SwiftData


@Model
final class FeeCalculation {
    @Attribute(.unique)
    var key: String // identifica ruta + inputs
    var currency: String
    var total:Double
    
    var chargesJSON: Data // Breakdown guardado como JSON

    
    var createdAt: Date
    var validUntil: Date // 24H
    
    init(key: String, currency: String = "NOK",total:Double, chargesJSON: Data, createdAt: Date, validUntil: Date) {
        self.key = key
        self.currency = currency
        self.total = 0.0
        self.chargesJSON = chargesJSON
        self.createdAt = createdAt
        self.validUntil = validUntil
    }
}
