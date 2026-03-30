//
//  BompengerService.swift
//  toll-app
//
//  Created by Carolina Mera  on 15/01/2026.

import Foundation

struct BompengerService {
    static let shared = BompengerService()
    private let baseURL = "https://dibkunnskapapi.azure-api.net/vCustomer"
    
    func getFeesByWaypoint(body: WaypointRequest) async throws -> WaypointResponse {
        let endpoint = "\(baseURL)/api/bomstasjoner/GetFeesByWaypoints"

        guard let url = URL(string: endpoint) else {
            throw GHError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OCP_APIM_SUBSCRIPTION_KEY") as? String ?? ""
        request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        #if DEBUG
        if let http = response as? HTTPURLResponse {
            print("Bompenger status: \(http.statusCode)")
        }
        if let bodyString = String(data: data, encoding: .utf8) {
            print("Bompenger body (first 800 chars): \(bodyString.prefix(800))")
        }
        #endif

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GHError.invalidResponse
        }

        do {
            let response = try JSONDecoder().decode(WaypointResponse.self, from: data)
            #if DEBUG
            print("Decoded successfully")
            print("   Tur count: \(response.tur?.count ?? 0)")
            if let trip = response.tur?.first {
                print("   Total price: \(trip.totalPrice ?? 0)")
                print("   Total with autopass: \(trip.totalWithAutopass ?? 0)")
            }
            #endif
            return response
        } catch {
            #if DEBUG
            print("Decoding error:", error)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: \(key.stringValue)")
                    print("   Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: \(type)")
                    print("   Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type)")
                    print("   Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
            #endif
            throw GHError.invalidData
        }
    }
}
