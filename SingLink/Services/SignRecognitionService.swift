//
//  SignRecognitionService.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation
internal import Combine

protocol SignRecognitionServiceProtocol {
    func predictSign(from handPoses: [HandPose]) async -> SignPrediction?
    func startSimulation()
    func stopSimulation()
}

class MockSignRecognitionService: SignRecognitionServiceProtocol, ObservableObject {
    @Published var isSimulating = false
    private var simulationTask: Task<Void, Never>?
    
    // Señas comunes en LSE (Lengua de Signos Española)
    private let commonSigns = [
        "Hola", "Gracias", "Por Favor", "Ayuda", "Agua",
        "Comida", "Baño", "Médico", "Dinero", "Casa",
        "Familia", "Amigo", "Trabajo", "Tiempo", "Nombre"
    ]
    
    func startSimulation() {
        guard !isSimulating else { return }
        
        isSimulating = true
        simulationTask = Task {
            while !Task.isCancelled && isSimulating {
                // Simular detección cada 2-4 segundos
                let delay = UInt64.random(in: 2_000_000_000...4_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
                
                if !Task.isCancelled {
                    await MainActor.run {
                        // Notificar que hay una nueva predicción disponible
                        ObjectWillChangePublisher().send()
                    }
                }
            }
        }
    }
    
    func stopSimulation() {
        isSimulating = false
        simulationTask?.cancel()
        simulationTask = nil
    }
    
    func predictSign(from handPoses: [HandPose]) async -> SignPrediction? {
        // Simular procesamiento
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
        
        // Solo predecir si hay poses de mano detectadas (en simulación, siempre hay)
        guard !handPoses.isEmpty else { return nil }
        
        let mainSign = commonSigns.randomElement() ?? "Hola"
        let confidence = Float.random(in: 0.7...0.95)
        
        // Generar alternativas realistas
        let alternatives = generateAlternativePredictions(mainSign: mainSign)
        
        return SignPrediction(
            sign: mainSign,
            confidence: confidence,
            alternativePredictions: alternatives,
            timestamp: Date()
        )
    }
    
    private func generateAlternativePredictions(mainSign: String) -> [String] {
        let alternatives = commonSigns.filter { $0 != mainSign }.shuffled()
        return Array(alternatives.prefix(3))
    }
}
