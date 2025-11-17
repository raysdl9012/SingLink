//
//  CalidadSenalView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct CalidadSenalView: View {
    let quality: SignalQuality
    let handCount: Int
    let confidence: Float
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Signal Quality Indicator
                SignalQualityIndicator(quality: quality)
                
                // Hand Count
                HStack(spacing: 4) {
                    Image(systemName: handCount > 0 ? "hand.raised.fill" : "hand.raised.slash.fill")
                        .foregroundColor(handCount > 0 ? .green : .gray)
                    
                    Text("\(handCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                // Confidence Level
                ConfidenceLevelView(confidence: confidence)
            }
            
            // Quality Description
            Text(quality.description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

enum SignalQuality {
    case excellent, good, fair, poor, none
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .none: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Excelente señal"
        case .good: return "Buena señal"
        case .fair: return "Señal regular"
        case .poor: return "Señal pobre"
        case .none: return "Sin señal"
        }
    }
    
    static func from(handCount: Int, confidence: Float) -> SignalQuality {
        guard handCount > 0 else { return .none }
        
        switch confidence {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }
}

struct SignalQualityIndicator: View {
    let quality: SignalQuality
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(quality == .none ? .gray : index < quality.barCount ? quality.color : .gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(index + 2) * 4)
            }
        }
    }
}

extension SignalQuality {
    var barCount: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        case .none: return 0
        }
    }
}

struct ConfidenceLevelView: View {
    let confidence: Float
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 6, height: 6)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(confidenceColor)
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CalidadSenalView(quality: .excellent, handCount: 2, confidence: 0.95)
        CalidadSenalView(quality: .good, handCount: 1, confidence: 0.75)
        CalidadSenalView(quality: .fair, handCount: 1, confidence: 0.55)
        CalidadSenalView(quality: .poor, handCount: 1, confidence: 0.35)
        CalidadSenalView(quality: .none, handCount: 0, confidence: 0.0)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
