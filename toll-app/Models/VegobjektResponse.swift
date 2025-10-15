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

// Modelo raíz que representa la respuesta completa de la API (un array de objetos VegobjektAPI)
struct VegobjektResponse: Decodable {
    let objekter: [VegobjektAPI] // 'objekter' es el array principal de peajes en la respuesta JSON
}

// Modelo temporal para cada peaje recibido de la API
struct VegobjektAPI: Decodable {
    let id: Int // Identificador único del peaje
    let href: String // Enlace a la API para este peaje
    let egenskaper: [EgenskapAPI] // Lista de propiedades/atributos del peaje
    let lokasjon: LokasjonAPI? // Información de localización (puede ser nil)
}

// Modelo temporal para cada propiedad/atributo de un peaje
struct EgenskapAPI: Decodable {
    let id: Int // Identificador de la propiedad
    let navn: String // Nombre de la propiedad
    let verdi: String? // Valor de la propiedad (puede ser String, Int o Double en el JSON, aquí siempre String)

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

// Modelo temporal para la localización del peaje
struct LokasjonAPI: Decodable {
    let geometri: GeometriAPI // Información geométrica (punto, línea, etc.)
}

// Modelo temporal para la geometría (coordenadas, sistema de referencia)
struct GeometriAPI: Decodable {
    let wkt: String // Representación WKT de la geometría
    let srid: Int // Código del sistema de referencia espacial
}
