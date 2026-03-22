import SwiftUI

struct TollPassedListView: View {
    let tolls: [Vegobjekt]

    var body: some View {
        NavigationView {
            List(tolls) { toll in
                VStack(alignment: .leading, spacing: 4) {
                    Text(toll.displayName)
                        .font(.headline)

//                    Text("ID: \(toll.id)")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Tolls on route (\(tolls.count))")
        }
    }


}

