//
//  TollStorageViewModel.swift
//  toll-app
//
//  Created by Carolina Mera  on 08/10/2025.
// Logica que guarda local los tolls

/*import SwiftUI

final class TollStorageViewModel : ObservableObject {
    
    @AppStorage("tollLocalData") private var tollDataJSON: String = "" // Guarda el JSON completo se guarda como texto "(String)" bajo la clave "tollLocalData"

    @Published var tolls: [Vegobjekt] = [] // @Published avisa a los views cuando cambian los datos (para actualizar la UI)
    
    
    // Función principal que carga los datos (primero localmente, luego de la API)
    func loadTolls() async {
        //1-Cargar: Carga los datos si existen (local)
        if !tollDataJSON.isEmpty { // si existen algo guardado local como string "text json"
            
            // Convertir: Convierte el String (que contiene texto en formato JSON) a tipo Data usando codificación UTF-8
            if let data = tollDataJSON.data(using: .utf8),
                
            // Decodifica ese Data en una lista de objetos Vegobjekt
            // (pasa de texto JSON A objetos reales [Vegobjekt])
            let decodedData = try? JSONDecoder().decode([Vegobjekt].self, from: data) {
                self.tolls = decodedData //Asigna los datos locales a la lista de tolls
                print("Load tolls from local storage")
            }
        }
        
        
        //ACTUALIZAR LOS DATOS DESDE LA API (para obtener datos más recientes) llamando el servicio "TollService" y actualizando
        do {
           //Llama a TollService para traer los peajes directamente desde internet
            let apiTolls = try await TollService.shared.getTolls()
            
            //Actualiza la lista local con los nuevos datos de la API
            self.tolls = apiTolls // apiTolls queda actualizada con la api
            
            //Convierte la lista [Vegobjekt] (objetos Swift) a JSON (Data)
            if let encodedData = try? JSONEncoder().encode(apiTolls),
               
               //Convierte ese Data a String (texto JSON) para poder guardarlo localmente

                   let jsonString = String(data:encodedData,encoding: .utf8){
                       // Guarda el JsonString en AppStorage (UserDefaults)
                       tollDataJSON = jsonString
                       print("Saved tolls to local storage")

                   }
            
        } catch {
            print("Error fetching API",error)
            
            
        }
        

    }
    
    
}

*/
