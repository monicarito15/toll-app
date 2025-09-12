import SwiftUI
import MapKit

struct SearchView: View {
    
    
    var body: some View {
        MapView()
        //.task {
        // The task modifier runs the async function automatically.
        //  await fetchTollsAsync()
        //}
    }
}
    // Use async/await for cleaner, more modern code.
    /*func fetchTollsAsync() async {
     
     let urlString = "https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45?inkluder=lokasjon&inkluder=egenskaper&antall=2"
     
     guard let url = URL(string: urlString) else {
     print("Invalid URL")
     return
     }
     
     var request = URLRequest(url: url)
     request.setValue("application/json", forHTTPHeaderField: "Accept")
     
     do {
     let (data, response) = try await URLSession.shared.data(for: request)
     
     if let httpResponse = response as? HTTPURLResponse {
     print("HTTP status code: \(httpResponse.statusCode)")
     print("HTTP headers: \(httpResponse.allHeaderFields)")
     }
     
     print("Data length: \(data.count) bytes")
     
     // Try to decode as JSON
     let json = try JSONSerialization.jsonObject(with: data, options: [])
     print("Decoded JSON:")
     print(json)
     
     // Try to convert to String
     if let jsonString = String(data: data, encoding: .utf8) {
     print("API response as String:")
     print(jsonString)
     }
     
     } catch {
     print("Error: \(error.localizedDescription)")
     }
     }*/

