//
//  ProcessingView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

// Vista que se muestra durante el procesamiento de señas
struct ProcessingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Icono giratorio
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            // Texto informativo
            VStack(spacing: 8) {
                Text("Procesando señas...")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Analizando gestos detectados")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ProcessingView()
}
