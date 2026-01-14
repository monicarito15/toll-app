import SwiftUI

struct TollSummaryBar: View {
    let tollCount: Int
    let total: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total tolls: \(tollCount)")
                        .font(.headline)

                    Text("Total price: \(Int(total)) kr")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Details")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.up")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }
}

