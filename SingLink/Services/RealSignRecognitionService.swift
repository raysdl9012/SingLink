//
//  RealSignRecognitionService.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation
import CoreML
internal import Combine

/**
 Servicio de reconocimiento de señas usando modelos Core ML entrenados.
 
 - Carga y gestiona modelos de machine learning
 - Realiza predicciones en tiempo real desde hand poses
 - Proporciona confianzas y alternativas de predicción
 */
@MainActor
final class RealSignRecognitionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isModelLoaded = false
    @Published var currentModelName: String?
    @Published var modelLoadError: String?
    
    // MARK: - Private Properties
    private var mlModel: MLModel?
    private var compiledModelURL: URL?
    
    // MARK: - Initialization
    init() {
        loadExistingModel()
    }
}

// MARK: - Model Management
extension RealSignRecognitionService {
    
    /// Carga un modelo Core ML compilado
    /// - Parameter modelURL: URL del modelo .mlmodelc
    func loadModel(from modelURL: URL) throws {
        do {
            mlModel = try MLModel(contentsOf: modelURL)
            currentModelName = modelURL.lastPathComponent
            isModelLoaded = true
            modelLoadError = nil
            
            print("✅ Modelo cargado: \(currentModelName ?? "Desconocido")")
            
        } catch {
            isModelLoaded = false
            modelLoadError = error.localizedDescription
            throw error
        }
    }
    
    /// Busca y carga automáticamente modelos disponibles
    private func loadExistingModel() {
        // Buscar en Bundle principal
        if let modelURL = findCompiledModelInBundle() {
            try? loadModel(from: modelURL)
            return
        }
        
        // Buscar en Documents (modelos descargados/entrenados)
        if let modelURL = findCompiledModelInDocuments() {
            try? loadModel(from: modelURL)
            return
        }
        
        modelLoadError = "No se encontraron modelos compilados"
    }
    
    private func findCompiledModelInBundle() -> URL? {
        // Buscar .mlmodelc en el bundle principal
        if let modelPath = Bundle.main.path(forResource: "HandPoseClassifier", ofType: "mlmodelc") {
            return URL(fileURLWithPath: modelPath)
        }
        return nil
    }
    
    private func findCompiledModelInDocuments() -> URL? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: nil
            )
            
            return contents.first { $0.pathExtension == "mlmodelc" }
        } catch {
            return nil
        }
    }
}

// MARK: - Prediction
extension RealSignRecognitionService {
    
    /// Realiza una predicción de seña desde hand poses
    /// - Parameter handPoses: Array de hand poses detectadas
    /// - Returns: Predicción con confianza y alternativas
    func predictSign(from handPoses: [HandPose]) -> SignPrediction? {
        guard isModelLoaded, let mlModel = mlModel else {
            print("❌ Modelo no cargado para predicción")
            return nil
        }
        
        // Usar la hand pose con mayor confianza
        guard let bestHandPose = handPoses.max(by: { $0.confidence < $1.confidence }) else {
            return nil
        }
        
        do {
            // Preparar input para el modelo
            let input = try prepareModelInput(from: bestHandPose)
            
            // Realizar predicción
            let prediction = try mlModel.prediction(from: input)
            
            // Procesar resultados
            return processPredictionResult(prediction, for: bestHandPose)
            
        } catch {
            print("❌ Error en predicción: \(error)")
            return nil
        }
    }
    
    /// Prepara el input del modelo desde una hand pose
    private func prepareModelInput(from handPose: HandPose) throws -> MLFeatureProvider {
        guard let multiArray = MLPreprocessor.convertHandPoseToMLMultiArray(handPose) else {
            throw PredictionError.inputPreparationFailed
        }
        
        // El input esperado depende de cómo nombre tu modelo las features
        let input = HandPoseClassifierInput(poses: multiArray)
        return input
    }
    
    /// Procesa el resultado de la predicción del modelo
    private func processPredictionResult(_ prediction: MLFeatureProvider, for handPose: HandPose) -> SignPrediction? {
        // Extraer la predicción principal
        guard let labelFeature = prediction.featureValue(for: "label"),
              let sign = labelFeature.stringValue else {
            return nil
        }
        
        // Extraer confianzas para todas las clases
        var confidence: Float = 0.0
        var alternativePredictions: [String] = []
        
        if let confidenceFeature = prediction.featureValue(for: "labelProbability") {
            if let confidenceDict = confidenceFeature.dictionaryValue as? [String: Double] {
                confidence = Float(confidenceDict[sign] ?? 0.0)
                
                // Obtener alternativas (top 3)
                alternativePredictions = confidenceDict
                    .sorted(by: { $0.value > $1.value })
                    .prefix(3)
                    .map { $0.key }
                    .filter { $0 != sign }
            }
        }
        
        return SignPrediction(
            sign: sign,
            confidence: confidence,
            alternativePredictions: alternativePredictions,
            timestamp: Date()
        )
    }
}

// MARK: - Model Information
extension RealSignRecognitionService {
    
    /// Obtiene información del modelo cargado
    func getModelInfo() -> String {
        guard let model = mlModel else {
            return "No hay modelo cargado"
        }
        
        let description = model.modelDescription
        return """
        Modelo: \(currentModelName ?? "Desconocido")
        Inputs: \(description.inputDescriptionsByName.keys.joined(separator: ", "))
        Outputs: \(description.outputDescriptionsByName.keys.joined(separator: ", "))
        """
    }
    
    /// Lista las señas que el modelo puede reconocer
    func getSupportedSigns() -> [String] {
        // Esto depende de cómo esté configurado tu modelo
        // Por ahora retornamos un array vacío, se llenará con el modelo real
        return []
    }
}

// MARK: - Error Handling
extension RealSignRecognitionService {
    enum PredictionError: Error {
        case inputPreparationFailed
        case modelNotLoaded
        case invalidPredictionResult
    }
}
