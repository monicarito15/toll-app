// Pagina princial

import SwiftUI
import MapKit

struct SearchView: View {
    let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 63.40504016561072, longitude: 10.425258382949021)
    //@State private var showSheet = true
    
    var body: some View {
        Map(){
            
            Marker("Carolina Home", coordinate: myLocation)
                .tint(.black)
        }
       
        
    }
        
            
}



