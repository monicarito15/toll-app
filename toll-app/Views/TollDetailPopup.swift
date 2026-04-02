import SwiftUI

struct TollDetailPopup: View {
    @Binding var selectedToll: TollCharge?
    
    var body: some View {
        if let toll = selectedToll {
            VStack {
                Spacer()
                
                HStack {
                    Text(toll.toll)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f kr", toll.price))
                        .font(.subheadline.weight(.semibold))
                    
                    Button {
                        withAnimation { selectedToll = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: selectedToll?.id)
            }
        }
    }
}
