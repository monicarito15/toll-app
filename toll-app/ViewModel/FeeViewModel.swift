
// Este ViewModel contiene: key - leer SwiftData (24h)- si no hay ( calcular/llamar API → guardar) - exponer totalPrice, tollCharges, lastFeeUpdate

import SwiftUI
import SwiftData

@MainActor
final class FeeViewModel: ObservableObject {
    
    @Published var tollCharges: [TollCharge] = []
    @Published var totalPrice: Double = 0
    @Published var lastFeeUpdate: Date?
    @Published var hasAutoPassAgreement: Bool = true
    
    //Funcion para crear el KEY
    private func roundTo15Min(_ date: Date) -> Date {
        let t = date.timeIntervalSince1970
        return Date(timeIntervalSince1970: floor(t / 900) * 900)
    }

    func feeCalculationKey(
        from: String,
        to: String,
        vehicle: VehicleType,
        fuel: FuelType,
        date: Date
    ) -> String {
        let rounded = roundTo15Min(date)
        return "\(from)|\(to)|\(vehicle)|\(fuel)|\(rounded.timeIntervalSince1970)|autopass:\(hasAutoPassAgreement)"
    }
    
    // Punto de entrada: usa cache 24h, si no existe crea placeholder (luego aquí metemos API real)
    func loadOrCalculateFees(
        tollsOnRoute: [Vegobjekt],
        from: String,
        to: String,
        vehicle: VehicleType,
        fuel: FuelType,
        date: Date,
        modelContext: ModelContext,
        storage: FeeStorageViewModel
    ) {
        guard !tollsOnRoute.isEmpty else {
            totalPrice = 0
            tollCharges = []
            lastFeeUpdate = nil
            return
        }
        
        let key = feeCalculationKey(from: from, to: to, vehicle: vehicle, fuel: fuel, date: date)
        
        //1- leer local
        
        storage.load(using: modelContext, key: key)
        
        if let saved = storage.calculation, storage.isValid(saved) {
            totalPrice = saved.total
            tollCharges = storage.decodeCharges(saved)
            lastFeeUpdate = saved.createdAt
            return
        }
        
        //2- Placeholder - por ahora es 0 - despues aqui se conecta el api real
        let charges = tollsOnRoute.map { v in
            let name = v.egenskaper.first(where: { $0.navn == "Navn bomstasjon"})?.verdi ?? "Ukjent"
            return TollCharge (id: "\(v.id)", toll: name, price: 0)
        }
        let total = charges.reduce(0) { $0 + $1.price }
        
        totalPrice = total
        tollCharges = charges
        lastFeeUpdate = Date()
        
        //3- Guardar 24H
        storage.save(using: modelContext, key: key, total: total, charges: charges, ttlHours: 24)
    }
}


