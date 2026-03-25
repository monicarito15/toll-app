//
//  Double​+​Currency​.swift
//  toll-app
//
//  Created by Carolina Mera on 25/03/2026.
//
import Foundation

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
