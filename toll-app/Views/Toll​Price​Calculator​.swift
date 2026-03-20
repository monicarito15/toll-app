//
//  TollPriceCalculator.swift
//  toll-app
//
//  Created by Carolina Mera on 20/03/2026.
//
//Calcula si la api fallo. calcula de precios de peajes (fallback cuando API no está disponible)
//plan B No hay internet o API falla o Faltan coordenadas
import Foundation


struct TollPriceCalculator {
    

    
    // Precios base por tipo de vehículo (en NOK)
    private struct BasePrices {
        static let car: Double = 30.0
        static let motorcycle: Double = 15.0
    }
    
    //Multiplicadores de descuento
    private struct Discounts {
        static let electric: Double = 0.5   // 50% descuento para eléctricos
        static let autopass: Double = 0.8   // 20% descuento con autopass
    }
    

    
    // Calcula el precio de un peaje individual
    static func calculateTollPrice(
        vehicleType: VehicleType,
        fuelType: FuelType,
        hasAutopass: Bool
    ) -> Double {
        // 1. Precio base según tipo de vehículo
        var price: Double
        switch vehicleType {
        case .car:
            price = BasePrices.car
        case .motorcycle:
            price = BasePrices.motorcycle
        }
        
        // 2. Aplicar descuento por vehículo eléctrico
        if fuelType == .electric {
            price *= Discounts.electric
        }
        
        // 3. Aplicar descuento por autopass
        if hasAutopass {
            price *= Discounts.autopass
        }
        
        // Redondear a 2 decimales
        return round(price * 100) / 100
    }
    
    // Calcula el precio total de múltiples peajes
    static func calculateTotalPrice(
        tollCount: Int,
        vehicleType: VehicleType,
        fuelType: FuelType,
        hasAutopass: Bool
    ) -> Double {
        let pricePerToll = calculateTollPrice(
            vehicleType: vehicleType,
            fuelType: fuelType,
            hasAutopass: hasAutopass
        )
        return pricePerToll * Double(tollCount)
    }
}


extension Double {
    // Formatea el precio en formato noruego (NOK)
    var asNOK: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NOK"
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self) kr"
    }
}



