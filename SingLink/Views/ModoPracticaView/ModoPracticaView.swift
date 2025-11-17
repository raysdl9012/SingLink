//
//  ModoPracticaView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Views/ModoPracticaView.swift
import SwiftUI

struct ModoPracticaView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var hapticManager = HapticManager.shared
    @State private var currentSign = "Hola"
    @State private var userAttempt = ""
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var score = 0
    @State private var attempts = 0
    
    let practiceSigns = [
        "Hola", "Gracias", "Por Favor", "Adiós", "Sí", "No",
        "Agua", "Comida", "Ayuda", "Baño", "Médico", "Familia"
    ]
    
    var accuracy: Double {
        guard attempts > 0 else { return 0.0 }
        return Double(score) / Double(attempts)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with Stats
                HStack {
                    VStack(alignment: .leading) {
                        Text("Modo Práctica")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("\(score)/\(attempts) correctos • \(Int(accuracy * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Cerrar") {
                        hapticManager.buttonPressed()
                        dismiss()
                    }
                }
                .padding(.horizontal)
                
                // Current Sign to Practice
                VStack(spacing: 20) {
                    Text("Practica esta seña:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(currentSign)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Feedback Area
                if showFeedback {
                    VStack(spacing: 16) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        Text(isCorrect ? "¡Correcto! 🎉" : "Intenta de nuevo")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Practice Controls
                VStack(spacing: 16) {
                    Button("Intenté hacer esta seña") {
                        simulateSignAttempt()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Siguiente Seña") {
                        nextSign()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
                
                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Consejos:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TipRow(icon: "hand.raised.fill", text: "Mantén las manos visibles")
                    TipRow(icon: "lightbulb.fill", text: "Buena iluminación ayuda")
                    TipRow(icon: "slowmo", text: "Movimientos claros y completos")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private func simulateSignAttempt() {
        attempts += 1
        
        // Simulate recognition (in real app, this would use actual ML)
        let isUserCorrect = Bool.random() // Simulate 50% accuracy for demo
        
        withAnimation {
            showFeedback = true
            isCorrect = isUserCorrect
            
            if isUserCorrect {
                score += 1
                hapticManager.notification(.success)
            } else {
                hapticManager.notification(.error)
            }
        }
        
        // Auto-advance after feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showFeedback = false
            }
            if isUserCorrect {
                nextSign()
            }
        }
    }
    
    private func nextSign() {
        withAnimation {
            currentSign = practiceSigns.filter { $0 != currentSign }.randomElement() ?? "Hola"
            showFeedback = false
        }
        hapticManager.selection()
    }
}

#Preview {
    ModoPracticaView()
}
