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


struct TollService{
    static let shared = TollService()
    
    func getTolls() async throws -> [Vegobjekt] {
        let endpoint = "https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45?inkluder=lokasjon&inkluder=egenskaper"
        guard let url = URL(string: endpoint) else {
            throw GHError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw GHError.invalidResponse
        }
        print("Raw API response: ", String(data: data, encoding: .utf8) ?? "<no string>")
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(VegobjektResponse.self, from: data)
            print("API object count: \(response.objekter.count)")
            for (index, toll) in response.objekter.enumerated() {
                print("Toll #\(index + 1): id=\(toll.id) egenskaper=\(toll.egenskaper.count)")
            }
            // Conversión de structs API a modelos SwiftData
            let vegobjekter: [Vegobjekt] = response.objekter.map { api in
                let egenskaper = api.egenskaper.map { e in
                    Egenskap(id: e.id, navn: e.navn, verdi: e.verdi)
                }
                let lokasjon: Lokasjon? = {
                    guard let l = api.lokasjon else { return nil }
                    let geo = Geometri(wkt: l.geometri.wkt, srid: l.geometri.srid)
                    return Lokasjon(geometri: geo)
                }()
                return Vegobjekt(id: api.id, href: api.href, egenskaper: egenskaper, lokasjon: lokasjon)
            }
            return vegobjekter
        } catch {
            print("Decoding error: ", error)
            throw GHError.invalidData
        }
    }
}
