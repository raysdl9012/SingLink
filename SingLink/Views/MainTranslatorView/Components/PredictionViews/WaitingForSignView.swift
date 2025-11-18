//
//  WaitingForSignView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct WaitingForSignView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Icono animado
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Texto informativo
            VStack(spacing: 8) {
                Text("Esperando señas...")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Realiza señas frente a la cámara")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            isAnimating = true
        }
    }
}
#Preview {
    WaitingForSignView()
}
