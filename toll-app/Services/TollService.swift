
//  Tollservice.swift
//  toll-app
//
//  Created by Carolina Mera  on 11/09/2025.
//API Service to fetch toll data

import Foundation

class TollService {
    static let shared = TollService()
    private init() {}
    
    // Async function to fetch tolls from API and decode them
    func fetchTollsAsync() async throws -> [Toll] {
        let urlString = "https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45?inkluder=lokasjon&inkluder=egenskaper&antall=2"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP status code: \(httpResponse.statusCode)")
            print("HTTP headers: \(httpResponse.allHeaderFields)")
        }
        print("Data length: \(data.count) bytes")
        let tollResponse = try JSONDecoder().decode(TollResponse.self, from: data)
        return tollResponse.objekter
    }
}


