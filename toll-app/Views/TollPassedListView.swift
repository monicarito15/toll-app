import SwiftUI

struct TollPassedListView: View {
    let tolls: [Vegobjekt]

    var body: some View {
        NavigationView {
            List(tolls) { toll in
                VStack(alignment: .leading, spacing: 4) {
                    Text(tollName(toll))
                        .font(.headline)

                    Text("ID: \(toll.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Tolls on route (\(tolls.count))")
        }
    }

    private func tollName(_ toll: Vegobjekt) -> String {
        toll.egenskaper.first(where: { $0.navn == "Navn bomstasjon" })?.verdi
        ?? toll.egenskaper.first(where: { $0.navn == "Navn bompengeanlegg (fra CS)" })?.verdi
        ?? "Unknown toll"
    }
}

