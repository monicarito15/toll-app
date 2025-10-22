//
//  VegobjektResponse.swift
//  toll-app
//
//  Created by Carolina Mera  on 14/10/2025.
//
//  Define los modelos temporales (structs) para decodificar la respuesta JSON de la API de peajes.
//  Se usan structs con sufijo API para separar los datos que vienen de la API de los modelos principales de la app (que suelen ser clases y usan SwiftData).
//  Así, puedes adaptar fácilmente los datos de la API antes de guardarlos en tu base de datos local.

import Foundation

struct VegobjektResponse: Decodable {
    let objekter: [VegobjektAPI]
}

struct VegobjektAPI: Decodable {
    let id: Int
    let href: String
    let egenskaper: [EgenskapAPI]
    let lokasjon: LokasjonAPI?
}

struct EgenskapAPI: Decodable {
    let id: Int
    let navn: String
    let verdi: String?

    enum CodingKeys: String, CodingKey {
        case id, navn, verdi
    }

    // Decodificador personalizado para manejar que 'verdi' puede ser String, Int o Double en el JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        navn = try container.decode(String.self, forKey: .navn)
        if let stringValue = try? container.decode(String.self, forKey: .verdi) {
            verdi = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .verdi) {
            verdi = String(intValue)
        } else if let doubleValue = try? container.decode(Double.self, forKey: .verdi) {
            verdi = String(doubleValue)
        } else {
            verdi = nil
        }
    }
}

struct LokasjonAPI: Decodable {
    let geometri: GeometriAPI
}

struct GeometriAPI: Decodable {
    let wkt: String
    let srid: Int
}
