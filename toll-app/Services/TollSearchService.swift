//
//  TollSearchService.swift
//  toll-app
//
//  Created by Carolina Mera  on 05/01/2026.
//
import MapKit

final class TollSearchService: ObservableObject {
    @Published var tollItems: [MKMapItem] = []
    
    func searchTolls(near coordinate: CLLocationCoordinate2D,
    span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)) {
        let region = MKCoordinateRegion(center: coordinate, span: span)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "toll"
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start {[weak self] response,error in
            guard let self, let response else { return }
            DispatchQueue.main.async {
                self.tollItems = response.mapItems
            }
        }
    }
}

