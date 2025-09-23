//  Tollservice.swift
//  toll-app
//
//  Created by Carolina Mera  on 11/09/2025.
//API Service to fetch toll data

import Foundation

enum GHError: Error {
    case invalidURL // bota un error si el URL es inválido
    case invalidResponse // bota un error si la respuesta es inválid
    case invalidData // bota un error si los datos son inválidos
}


struct TollService: Decodable {
    static let shared = TollService()
    
    
    func getTolls() async throws -> [Vegobjekt] { //get tolls async
        let endpoint = "https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45?inkluder=lokasjon&inkluder=egenskaper&antall=2"
        
        guard let url = URL(string: endpoint) else { //getting the URL
            throw GHError.invalidURL } // si hay un error de URL inválida
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // response si no hay un error
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { // si la respuesta 200 -> está bien
            throw GHError.invalidResponse // si la respuesta es inválida
        }

        print("Raw API response: ", String(data: data, encoding: .utf8) ?? "<no string>")
        
        //get data
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase // convierte si es q se encuentra cammelCase
            let response = try decoder.decode(VegokbjektResponse.self, from: data)
            return response.objekter
        } catch {
            print("Decoding error: ", error)
            throw GHError.invalidData // si los datos son inválidos
            
            
        }
        
     
    }
    
    
}
