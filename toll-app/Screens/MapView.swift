
import SwiftUI
import MapKit

struct MapView: View {
    @State private var tolls: [Toll] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 63.40504016561072, longitude: 10.425258382949021),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )

    var body: some View {
        Map {
            ForEach(tolls) { toll in
                Marker("\(toll.id): \(toll.navn)", coordinate: toll.coordinate)
                    .tint(.red)
            }
        }
        .task {
            do {
                tolls = try await TollService.shared.fetchTollsAsync()
                if let first = tolls.first {
                    region.center = first.coordinate
                }
            } catch {
                print("Error fetching tolls: \(error.localizedDescription)")
            }
        }
    }
    
}
//#Preview {
  //  MapView()
//}
 
