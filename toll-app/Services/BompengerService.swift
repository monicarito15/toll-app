//
//  BompengerService.swift
//  toll-app
//
//  Created by Carolina Mera  on 15/01/2026.
//Key 001b220867b54e1a9280b22455233412

import Foundation

struct BompengerService {
    static let shared = BompengerService()
    private let baseURL = "https://dibkunnskapapi.azure-api.net/vCustomer" // Base URL for the API - just for testing
    
    
    
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
        
        /*
         {
             "Fra":{
                 "Latitude": "59.91122", "Longitude": "10.75356"
             },
             "Til":{
                 "Latitude": "63.4305", "Longitude": "10.3951"
             },
             "Dato_yyyymmdd":"20190528",
             "Tidspunkt_hhmm":"1701",
             "Bilsize":1,
             "Litenbiltype":1,
             "Storbiltype":0,
             "Billengdeunder":"5.0",
             "Retur":"0",
             "Tidsreferanser":"1"
         }
         */

            // ⚠️ Azure API Management suele requerir subscription key:
            // request.setValue("<TU_SUBSCRIPTION_KEY>", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")

            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            print(response)

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
        
        
        
        
        
 

