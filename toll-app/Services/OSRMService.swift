import MapKit

// Llama al servidor público de OSRM (OpenStreetMap routing) para obtener hasta 3 rutas alternativas.

// OSRM devuelve rutas reales por distintos corredores de carretera, a diferencia de MapKit
// que solo retorna 1 ruta para distancias largas en Noruega.
struct OSRMService {

    static let shared = OSRMService()

    private let baseURL = "https://router.project-osrm.org/route/v1/driving"

    func getRoutes(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> [AppRoute] {
        let urlStr = "\(baseURL)/\(from.longitude),\(from.latitude);\(to.longitude),\(to.latitude)?alternatives=3&overview=full&geometries=polyline&steps=true"
        guard let url = URL(string: urlStr) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OSRMResponse.self, from: data)
            return response.routes.enumerated().map { index, route in
                let coords = decodePolyline(route.geometry)
                let polyline = MKPolyline(coordinates: coords, count: coords.count)
                let name = index == 0 ? "Fastest" : "Alternative \(index)"
                let hasFerry = route.legs.flatMap { $0.steps }.contains { $0.mode == "ferry" }
                return AppRoute(
                    polyline: polyline,
                    distance: route.distance,
                    expectedTravelTime: route.duration,
                    name: name,
                    hasFerry: hasFerry
                )
            }
        } catch {
            #if DEBUG
            print("OSRM error: \(error)")
            #endif
            return []
        }
    }

    // Decodifica el formato de polyline codificada de Google/OSRM
    private func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        var lat = 0
        var lon = 0
        var index = encoded.startIndex

        while index < encoded.endIndex {
            var result = 0
            var shift = 0
            var byte: Int
            repeat {
                guard index < encoded.endIndex else { break }
                byte = Int(encoded[index].asciiValue ?? 63) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = encoded.index(after: index)
            } while byte >= 0x20
            lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1)

            result = 0
            shift = 0
            repeat {
                guard index < encoded.endIndex else { break }
                byte = Int(encoded[index].asciiValue ?? 63) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = encoded.index(after: index)
            } while byte >= 0x20
            lon += (result & 1) != 0 ? ~(result >> 1) : (result >> 1)

            coords.append(CLLocationCoordinate2D(
                latitude: Double(lat) / 1e5,
                longitude: Double(lon) / 1e5
            ))
        }
        return coords
    }
}

private struct OSRMResponse: Codable {
    let routes: [OSRMRoute]
}

private struct OSRMRoute: Codable {
    let distance: Double
    let duration: Double
    let geometry: String
    let legs: [OSRMLeg]
}

private struct OSRMLeg: Codable {
    let steps: [OSRMStep]
}

private struct OSRMStep: Codable {
    let mode: String
}
