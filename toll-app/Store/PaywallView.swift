//
//  PaywallView.swift
//  toll-app
//
//  Shown when the user hits the free search limit.

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "road.lanes")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
                    .padding(.top, 40)

                Text("Unlock Unlimited Searches")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("You've used all \(PurchaseManager.freeSearchLimit) free route searches.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                BenefitRow(icon: "infinity", text: "Unlimited route searches")
                BenefitRow(icon: "clock.arrow.circlepath", text: "Full search history")
                BenefitRow(icon: "iphone", text: "One-time purchase, forever")
            }
            .padding(24)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer()

            // Error
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Buttons
            VStack(spacing: 12) {
                Button {
                    Task { await buyUnlimited() }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Unlock for 19 kr")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isPurchasing)

                Button("Restore Purchase") {
                    Task { await purchaseManager.restorePurchases() }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button("Not now") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onChange(of: purchaseManager.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }

    private func buyUnlimited() async {
        isPurchasing = true
        errorMessage = nil
        do {
            try await purchaseManager.purchase()
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
        isPurchasing = false
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.orange)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
        }
    }
}
