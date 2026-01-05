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
    
    // funcion para obtener los tolls
    func getTolls() async throws -> [Vegobjekt] {
        let endpoint = "https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45?inkluder=lokasjon&inkluder=egenskaper"
        
        guard let url = URL(string: endpoint) else { // verificacion de la URL sea valida, si no lanza un error
            throw GHError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("toll-app (carolina.m@gmail.com)", forHTTPHeaderField: "X-Client") // cambiarlo despues con un correo verdadero

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("NVDB status: \(http.statusCode)")
            print("NVDB headers: \(http.allHeaderFields)")
        }

        if let bodyString = String(data: data, encoding: .utf8) {
            print("NVDB body (first 500 chars): \(bodyString.prefix(500))")
        }
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw GHError.invalidResponse
        }
        //print("Raw API response: ", String(data: data, encoding: .utf8) ?? "<no string>")
        do {
            // se crea un decodificador JSON
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // Decodifica los datos del API
            let response = try decoder.decode(VegobjektResponse.self, from: data)
            print("API object count: \(response.objekter.count)")
            
            //Toma cada peaje recibido y los imprime
            for (index, toll) in response.objekter.enumerated() {
                //print("Toll #\(index + 1): id=\(toll.id) egenskaper=\(toll.egenskaper.count)")
            }
            // Conversión de structs API a modelos SwiftData
            let vegobjekter: [Vegobjekt] = response.objekter.map { api in
                
                // Convierte las propiedades "egenskaper"
                let egenskaper = api.egenskaper.map { e in
                    Egenskap(id: e.id, navn: e.navn, verdi: e.verdi)
                }
                
                // Convierte el objeto de localización si existe
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

