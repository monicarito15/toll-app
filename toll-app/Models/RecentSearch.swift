//
//  RecentSaerch.swift
//  toll-app
//
//  Created by Carolina Mera  on 21/10/2025.
//

import Foundation
import SwiftData

@Model
final class RecentSearch {
    var name: String
    var address: String
    var createdAt: Date
    
    init(name: String, address: String,createdAt: Date = Date()) {
        self.name = name
        self.address = address
        self.createdAt = createdAt
    }
    
}


