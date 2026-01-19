//
//  BompengerService.swift
//  toll-app
//
//  Created by Carolina Mera  on 15/01/2026.
//Key 001b220867b54e1a9280b22455233412

import Foundation

struct BompengerService {
    static let shared = BompengerService()
    private let baseURL = "https://dibkunnskapapi.developer.azure-api.net" // Base URL for the API - just for testing

    
    
    
    func getFeesByWaypointList(body: WaypointRequest) async throws -> WaypointResponse {
            let endpoint = "\(baseURL)/api/bomstasjoner/GetFeesByWaypointList"

            guard let url = URL(string: endpoint) else {
                throw GHError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // ⚠️ Azure API Management suele requerir subscription key:
            // request.setValue("<TU_SUBSCRIPTION_KEY>", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")

            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("Bompenger status: \(http.statusCode)")
            }
            if let bodyString = String(data: data, encoding: .utf8) {
                print("Bompenger body (first 800 chars): \(bodyString.prefix(800))")
            }

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw GHError.invalidResponse
            }

            do {
                return try JSONDecoder().decode(WaypointResponse.self, from: data)
            } catch {
                print("Decoding error:", error)
                throw GHError.invalidData
            }
        }
    }
        
        
        
        
        
 

