//
//  TutorialView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Paso 1
                    TutorialStep(
                        number: 1,
                        icon: "play.circle.fill",
                        title: "Iniciar Cámara",
                        description: "Presiona el botón de reproducir para activar la cámara"
                    )
                    
                    // Paso 2
                    TutorialStep(
                        number: 2,
                        icon: "hand.raised.fill",
                        title: "Realizar Señas",
                        description: "Realiza las señas frente a la cámara con las manos bien visibles"
                    )
                    
                    // Paso 3
                    TutorialStep(
                        number: 3,
                        icon: "text.bubble.fill",
                        title: "Leer Traducción",
                        description: "La app traducirá las señas a texto en tiempo real"
                    )
                    
                    // Paso 4
                    TutorialStep(
                        number: 4,
                        icon: "clock.arrow.circlepath",
                        title: "Revisar Historial",
                        description: "Accede al historial para ver conversaciones anteriores"
                    )
                    
                    // Consejos
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Consejos para Mejor Precisión")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TipRow(icon: "lightbulb.fill", text: "Buena iluminación en la habitación")
                        TipRow(icon: "lightbulb.fill", text: "Manos frente a fondo contrastante")
                        TipRow(icon: "lightbulb.fill", text: "Señas claras y completas")
                        TipRow(icon: "lightbulb.fill", text: "Evitar movimientos bruscos")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Cómo Usar SignLink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
}


struct TutorialStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Número del paso
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    TutorialView()
}
