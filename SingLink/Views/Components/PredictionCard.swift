//
//  PredictionCard.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct PredictionCard: View {
    let prediction: SignPrediction // ← Ahora recibe SignPrediction completo
    let showConfidence: Bool // ← Nuevo parámetro
    
    init(prediction: SignPrediction, showConfidence: Bool = true) {
        self.prediction = prediction
        self.showConfidence = showConfidence
    }
    
    private var confidenceColor: Color {
        switch prediction.confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private var confidenceIcon: String {
        switch prediction.confidence {
        case 0.8...1.0: return "checkmark.circle.fill"
        case 0.6..<0.8: return "exclamationmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Predicción principal
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seña Detectada:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(prediction.sign)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                
                if showConfidence {
                    ConfidenceIndicator(confidence: prediction.confidence)
                }
            }
            
            // Alternativas
            if !prediction.alternativePredictions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Otras posibilidades:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(prediction.alternativePredictions, id: \.self) { alternative in
                            Text(alternative)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Timestamp (opcional)
            HStack {
                Text("Detectado: \(prediction.timestamp, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct ConfidenceIndicator: View {
    let confidence: Float
    
    private var color: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private var icon: String {
        switch confidence {
        case 0.8...1.0: return "checkmark.circle.fill"
        case 0.6..<0.8: return "exclamationmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(8)
        .background(color.opacity(0.2))
        .clipShape(Circle())
    }
}

#Preview {
    VStack {
        PredictionCard(
            prediction: SignPrediction(
                sign: "Hola",
                confidence: 0.92,
                alternativePredictions: ["Gracias", "Ayuda", "Por Favor"],
                timestamp: Date()
            )
        )
        
        PredictionCard(
            prediction: SignPrediction(
                sign: "Gracias",
                confidence: 0.75,
                alternativePredictions: ["Por Favor", "Hola"],
                timestamp: Date()
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

