
//  Tollservice.swift
//  toll-app
//
//  Created by Carolina Mera  on 11/09/2025.
//API Service to fetch toll data

/*
import Foundation

struct TollService: Decodable {
    static let shared = TollService()
    private init() {}
    
    private enum TollServiceError: Error {
        case invalidResponse
        case decodingError(Error)
    }
    
    func fetchTollsAsync(at: url: URL) async throws -> [Vegobjekt] {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TollServiceError.invalidResponse
        }
        
        JSONDecoder.decode([Vegobjekt].self, from:  data)
        
        return []
    }
}
    
    
    
   
    // Async function to fetch tolls from API and decode them
    func fetchTollsAsync() async throws -> [Vegobjekt] {
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
        print(response)
        return tollResponse.objekter
    }
}


*/
