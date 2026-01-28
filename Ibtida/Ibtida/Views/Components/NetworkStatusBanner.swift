//
//  NetworkStatusBanner.swift
//  Ibtida
//
//  Non-blocking network status banner
//

import SwiftUI

struct NetworkStatusBanner: View {
    let message: String
    let isRetrying: Bool
    let onRetry: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            if isRetrying {
                ProgressView()
                    .tint(.mutedGold)
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mutedGold)
            }
            
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.warmText(colorScheme))
            
            Spacer()
            
            if let onRetry = onRetry, !isRetrying {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.mutedGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.mutedGold.opacity(0.15))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmCard(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.mutedGold.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        NetworkStatusBanner(
            message: "No internet connection. Retrying...",
            isRetrying: true,
            onRetry: nil
        )
        
        NetworkStatusBanner(
            message: "No internet connection.",
            isRetrying: false,
            onRetry: { print("Retry tapped") }
        )
    }
    .padding()
}
