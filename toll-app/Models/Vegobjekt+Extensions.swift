//
//  Vegobjekt+Extensions.swift
//  toll-app
//
//  Extensiones para el modelo Vegobjekt
//

import Foundation
import CoreLocation

extension Vegobjekt {
    // Obtiene el nombre del toll desde sus propiedades
    // Busca primero "Navn bomstasjon", luego "Navn bompengeanlegg (fra CS)" si no lo encuentra un nombre retorna UNKNOWN
    
    var displayName: String {
        // Buscar "Navn bomstasjon" primero
        if let navn = egenskaper.first(where: { $0.navn == "Navn bomstasjon" })?.verdi {
            return navn
        }
        
        // Si no existe, buscar "Navn bompengeanlegg (fra CS)"
        if let navn = egenskaper.first(where: { $0.navn == "Navn bompengeanlegg (fra CS)" })?.verdi {
            return navn
        }
        
        // Si tampoco existe, retornar "Unknown Toll"
        return "Unknown Toll"
    }
    
    // Obtiene la ubicación del toll (Fylke y/o Kommune)
    // String con la ubicación o nil si no está disponible
    var location: String? {
        let fylke = egenskaper.first(where: { $0.navn == "Fylke" })?.verdi
        let kommune = egenskaper.first(where: { $0.navn == "Kommune" })?.verdi
        
        if let fylke = fylke, let kommune = kommune {
            return "\(kommune), \(fylke)"
        } else if let fylke = fylke {
            return fylke
        } else if let kommune = kommune {
            return kommune
        }
        
        return nil
    }
    
    // Distance Calculation
    
    // Calcula la distancia desde un punto de referencia hasta este toll
    // Parameter from: Coordenada de referencia (ej: ubicación del usuario)
    // Returns: String formateado con la distancia o "—" si no hay coordenadas
    func distance(from referenceLocation: CLLocationCoordinate2D) -> String {
        guard let tollCoords = lokasjon?.coordinates else { return "—" }
        
        let referencePoint = CLLocation(latitude: referenceLocation.latitude, longitude: referenceLocation.longitude)
        let tollLocation = CLLocation(latitude: tollCoords.latitude, longitude: tollCoords.longitude)
        let distance = referencePoint.distance(from: tollLocation)
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    //Calcula la distancia en metros desde un punto de referencia
    //Parameter from: Coordenada de referencia
    //Returns: Distancia en metros o nil si no hay coordenadas
    func distanceInMeters(from referenceLocation: CLLocationCoordinate2D) -> Double? {
        guard let tollCoords = lokasjon?.coordinates else { return nil }
        
        let referencePoint = CLLocation(latitude: referenceLocation.latitude, longitude: referenceLocation.longitude)
        let tollLocation = CLLocation(latitude: tollCoords.latitude, longitude: tollCoords.longitude)
        return referencePoint.distance(from: tollLocation)
    }
}

