//
//  Vegobjekt.swift
//  toll-app
//
//  Created by Carolina Mera  on 12/09/2025.
//Data model for Vegobjekt API response

import Foundation
import CoreLocation
import ArcGIS
import SwiftData
 
@Model
class Vegobjekt: Identifiable {
    @Attribute(.unique)
    var id: Int
    var href: String
    @Relationship(deleteRule: .cascade)
    var egenskaper: [Egenskap]
    var lokasjon: Lokasjon?
    
    init(id: Int, href: String, egenskaper: [Egenskap], lokasjon: Lokasjon?) {
        self.id = id
        self.href = href
        self.egenskaper = egenskaper
        self.lokasjon = lokasjon
    }
    
    // Pricing fom NVDB egenskaper
    var normalPriceCar: Double? {
          egenskaper.first(where: { $0.navn == "Takst liten bil" })
              .flatMap { Double($0.verdi ?? "") }
      }
      var rushPriceCar: Double? {
          egenskaper.first(where: { $0.navn == "Rushtidstakst liten bil" })
              .flatMap { Double($0.verdi ?? "") }
      }

      var hasRushHourPricing: Bool {
          egenskaper.first(where: { $0.navn == "Tidsdifferensiert takst" })?.verdi == "Ja"
      }
    var stationName: String {
        egenskaper.first(where: { $0.navn == "Navn bomstasjon"})?.verdi ?? "No name toll"
    }
                                                                                                                                                                                                             
      func price(vehicle: VehicleType, fuel: FuelType, date: Date) -> Double? {
          guard let base = normalPriceCar else { return nil }
                                                                                                                                                                                                               
          let isRush = hasRushHourPricing && date.isRushHour()
          let carPrice = isRush ? (rushPriceCar ?? base) : base
                                                                                                                                                                                                               
          switch fuel {
          case .electric:
              return carPrice * 0.5
          default:
              return carPrice
          }
      }
}
