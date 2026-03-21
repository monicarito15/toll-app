//
//  SearchHistoryItem.swift
//  toll-app
//
//  Modelo para guardar el historial de búsquedas de rutas
//

import Foundation
import SwiftData

@Model
class SearchHistoryItem: Identifiable {
    var id: UUID
    var fromAddress: String
    var toAddress: String
    var vehicleType: String // VehicleType como String para persistencia
    var fuelType: String // FuelType como String para persistencia
    var dateTime: Date
    var hasAutopass: Bool
    var searchDate: Date // Cuándo se hizo la búsqueda
    var totalPrice: Double
    var tollCount: Int
    
    init(
        fromAddress: String,
        toAddress: String,
        vehicleType: VehicleType,
        fuelType: FuelType,
        dateTime: Date,
        hasAutopass: Bool,
        totalPrice: Double = 0,
        tollCount: Int = 0
    ) {
        self.id = UUID()
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.vehicleType = vehicleType.rawValue
        self.fuelType = fuelType.rawValue
        self.dateTime = dateTime
        self.hasAutopass = hasAutopass
        self.searchDate = Date()
        self.totalPrice = totalPrice
        self.tollCount = tollCount
    }
    
    // Computed properties para facilitar el uso
    var vehicleTypeEnum: VehicleType {
        VehicleType(rawValue: vehicleType) ?? .car
    }
    
    var fuelTypeEnum: FuelType {
        FuelType(rawValue: fuelType) ?? .gas
    }
    
    // Descripción legible de la búsqueda
    var routeDescription: String {
        "\(fromAddress) → \(toAddress)"
    }
    
    // Descripción del tiempo transcurrido
    var timeAgo: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(searchDate) {
            let components = calendar.dateComponents([.hour, .minute], from: searchDate, to: now)
            if let hours = components.hour, hours > 0 {
                return "Hace \(hours)h"
            } else if let minutes = components.minute, minutes > 0 {
                return "Hace \(minutes)m"
            } else {
                return "Ahora"
            }
        } else if calendar.isDateInYesterday(searchDate) {
            return "Ayer"
        } else {
            let components = calendar.dateComponents([.day], from: searchDate, to: now)
            if let days = components.day, days <= 30 {
                return "Hace \(days)d"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: searchDate)
            }
        }
    }
}
