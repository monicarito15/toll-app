////
////  TollPriceCalculator.swift
////  toll-app
////
////  Created by Carolina Mera on 20/03/2026.
////
////Calcula si la api fallo. calcula de precios de peajes (fallback cuando API no está disponible)
////plan B No hay internet o API falla o Faltan coordenadas
//import Foundation
//
//
//struct TollPriceCalculator {
//    
//
//    
//    //  PRECIOS ESTIMADOS - Solo para fallback cuando API no está disponible
//    // Basados en promedios de tarifas de peaje en Noruega (2026)
//    // NOTA: Estos NO son los precios reales, solo aproximaciones
//    private struct BasePrices {
//        static let car: Double = 35.0        // Promedio estimado para carro
//        static let motorcycle: Double = 17.5  // Promedio estimado para moto
//    }
//    
//    // Multiplicadores de descuento aproximados
//    private struct Discounts {
//        static let electric: Double = 0.6   // ~40% descuento para eléctricos (varía por ubicación)
//        static let autopass: Double = 0.8   // ~20% descuento con autopass
//    }
//    
//
//    
//    // Calcula el precio de un peaje individual
//    static func calculateTollPrice(
//        vehicleType: VehicleType,
//        fuelType: FuelType,
//        hasAutopass: Bool
//    ) -> Double {
//        print("LOCAL PRICE CALCULATOR (Fallback):")
//        print("Input - Vehicle: \(vehicleType.rawValue), Fuel: \(fuelType.rawValue), Autopass: \(hasAutopass)")
//        
//        // 1. Precio base según tipo de vehículo
//        var price: Double
//        switch vehicleType {
//        case .car:
//            price = BasePrices.car
//            print("   Base price (car): \(price) NOK")
//        case .motorcycle:
//            price = BasePrices.motorcycle
//            print("   Base price (motorcycle): \(price) NOK")
//        }
//        
//        // 2. Aplicar descuento por vehículo eléctrico
//        if fuelType == .electric {
//            let originalPrice = price
//            price *= Discounts.electric
//            print("   Electric discount: \(originalPrice) × \(Discounts.electric) = \(price) NOK")
//        }
//        
//        // 3. Aplicar descuento por autopass
//        if hasAutopass {
//            let originalPrice = price
//            price *= Discounts.autopass
//            print("   Autopass discount: \(originalPrice) × \(Discounts.autopass) = \(price) NOK")
//        }
//        
//        // Redondear a 2 decimales
//        let finalPrice = round(price * 100) / 100
//        print("   Final price per toll: \(finalPrice) NOK")
//        
//        return finalPrice
//    }
//    
//    // Calcula el precio total de múltiples peajes
//    static func calculateTotalPrice(
//        tollCount: Int,
//        vehicleType: VehicleType,
//        fuelType: FuelType,
//        hasAutopass: Bool
//    ) -> Double {
//        let pricePerToll = calculateTollPrice(
//            vehicleType: vehicleType,
//            fuelType: fuelType,
//            hasAutopass: hasAutopass
//        )
//        return pricePerToll * Double(tollCount)
//    }
//}
//
//
//extension Double {
//    // Formatea el precio en formato noruego (NOK)
//    var asNOK: String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.currencyCode = "NOK"
//        formatter.locale = Locale(identifier: "nb_NO")
//        return formatter.string(from: NSNumber(value: self)) ?? "\(self) kr"
//    }
//}
//
//
//
