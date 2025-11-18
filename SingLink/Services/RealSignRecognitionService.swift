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
final class RealSignRecognitionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isModelLoaded = false
    @Published var currentModelName: String?
    @Published var modelLoadError: String?
    @Published var supportedSigns: [String] = []
    
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
            print("🏷️ Señas soportadas: \(supportedSigns)")
            
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
        // Buscar .mlmodelc en el bundle principal con el nombre correcto
        if let modelPath = Bundle.main.path(forResource: "MLSingLink", ofType: "mlmodelc") {
            return URL(fileURLWithPath: modelPath)
        }
        
        // Buscar alternativas
        let possibleNames = ["MLSingLink", "HandPoseClassifier", "SignLanguageModel"]
        for name in possibleNames {
            if let modelPath = Bundle.main.path(forResource: name, ofType: "mlmodelc") {
                return URL(fileURLWithPath: modelPath)
            }
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
            
            // Buscar MLSingLink específicamente
            if let mlSingLink = contents.first(where: { $0.lastPathComponent == "MLSingLink.mlmodelc" }) {
                return mlSingLink
            }
            
            // O cualquier modelo compilado
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
            print("predicted class label: \(prediction.featureNames)")
            // Procesar resultados
            return processPredictionResult(prediction, for: bestHandPose)
            
        } catch {
            print("❌ Error en predicción: \(error)")
            return nil
        }
    }
    
    /// Prepara el input del modelo desde una hand pose
    private func prepareModelInput(from handPose: HandPose) throws -> MLFeatureProvider {
        // Crear un diccionario con TODAS las características que el modelo espera
        var featureDictionary: [String: MLFeatureValue] = [:]
        
        // El modelo espera 21 puntos * 2 coordenadas = 42 características
        let totalPoints = 21
        
        // Para cada punto 0-20, agregar x e y
        for i in 0..<totalPoints {
            let xKey = "point_\(i).x"
            let yKey = "point_\(i).y"
            
            if i < handPose.points.count {
                let point = handPose.points[i]
                // Asegurar que las coordenadas estén en rango [0,1]
                let x = max(0.0, min(1.0, point.x))
                let y = max(0.0, min(1.0, point.y))
                
                featureDictionary[xKey] = MLFeatureValue(double: x)
                featureDictionary[yKey] = MLFeatureValue(double: y)
            } else {
                // Si faltan puntos, usar valores por defecto (0,0)
                featureDictionary[xKey] = MLFeatureValue(double: 0.0)
                featureDictionary[yKey] = MLFeatureValue(double: 0.0)
            }
        }
        
        print("🔍 Enviando \(featureDictionary.count) características al modelo")
        
        // Crear el feature provider con TODAS las características
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: featureDictionary)
        return featureProvider
    }
    
    /// Determina el nombre correcto del input basado en la descripción del modelo
    private func determineInputName() -> String {
        // Para modelos Tabular Data, NO usamos un solo nombre de input
        // En su lugar, el modelo espera múltiples características individuales
        // Por eso el método prepareModelInput ahora crea un diccionario completo
        
        print("🔍 Modelo Tabular Data - Usando múltiples características")
        return "" // No se usa para este tipo de modelo
    }
    
    /// Convierte HandPose a array de características para el modelo
    private func convertHandPoseToFeatureArray(_ handPose: HandPose) -> [Double] {
        var features: [Double] = []
        
        for point in handPose.points {
            features.append(Double(point.x))
            features.append(Double(point.y))
        }
        
        // Asegurar tamaño consistente (21 puntos * 2 coordenadas = 42 características)
        while features.count < 42 {
            features.append(0.0)
        }
        
        // Si tenemos más de 42 características, tomar solo las primeras 42
        if features.count > 42 {
            features = Array(features.prefix(42))
        }
        
        return features
    }
    
    private func processPredictionResult(_ prediction: MLFeatureProvider, for handPose: HandPose) -> SignPrediction? {
        var predictedSign: String = "Desconocido"
        var confidence: Float = handPose.confidence
        var alternativePredictions: [String] = []
        
        // CORRECCIÓN: No usar conditional binding para propiedades no-opcionales
        // En su lugar, verificar directamente los valores
        
        // 1. Buscar la predicción principal (classLabel)
        let classLabelFeature = prediction.featureValue(for: "classLabel")
        if classLabelFeature?.type == .string {
            let stringValue = classLabelFeature!.stringValue
            if !stringValue.isEmpty {
                predictedSign = stringValue
                print("✅ Predicción classLabel: \(predictedSign)")
            }
        }
        
        // 2. Buscar probabilidades para confianza
        let probabilitiesFeature = prediction.featureValue(for: "labelProbability")
        if probabilitiesFeature?.type == .dictionary {
            let dictionaryValue = probabilitiesFeature!.dictionaryValue
            
            print("🔍 Probabilidades encontradas: \(dictionaryValue.count) items")
            
            // Convertir a array de (key, value) y ordenar
            var sortedPredictions: [(String, Double)] = []
            
            for (key, value) in dictionaryValue {
                let stringKey = "\(key)" // Convertir AnyHashable a String
                let doubleValue = value.doubleValue
                sortedPredictions.append((stringKey, doubleValue))
            }
            
            // Ordenar por confianza (mayor a menor)
            sortedPredictions.sort { $0.1 > $1.1 }
            
            if let topPrediction = sortedPredictions.first {
                predictedSign = topPrediction.0
                confidence = Float(topPrediction.1)
                
                // Crear alternativas (excluyendo la predicción principal)
                alternativePredictions = Array(sortedPredictions.prefix(4))
                    .map { $0.0 }
                    .filter { $0 != predictedSign }
                
                print("✅ Predicción final: \(predictedSign) - Confianza: \(confidence)")
            }
        }
        
        // 3. Si no encontramos classLabel, buscar en otros outputs
        if predictedSign == "Desconocido" {
            let alternativeOutputs = ["label", "prediction", "output"]
            for outputName in alternativeOutputs {
                let feature = prediction.featureValue(for: outputName)
                if feature?.type == .string {
                    let stringValue = feature!.stringValue
                    if !stringValue.isEmpty {
                        predictedSign = stringValue
                        print("✅ Predicción \(outputName): \(predictedSign)")
                        break
                    }
                }
            }
        }
        
        // 4. Si no hay alternativas, usar señas por defecto
        if alternativePredictions.isEmpty {
            alternativePredictions = supportedSigns
                .filter { $0 != predictedSign }
                .prefix(3)
                .map { $0 }
        }
        
        return SignPrediction(
            id: UUID(),
            sign: predictedSign,
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
        Señas soportadas: \(supportedSigns.joined(separator: ", "))
        """
    }
    
    /// Lista las señas que el modelo puede reconocer
    func getSupportedSigns() -> [String] {
        return supportedSigns
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

// MARK: - Helper para debugging
extension RealSignRecognitionService {
    
    /// Debug: muestra información detallada del modelo
    func debugModelInfo() {
        guard let model = mlModel else {
            print("❌ No hay modelo cargado")
            return
        }
        
        let description = model.modelDescription
        print("""
        🔍 DEBUG MODEL INFO:
        • Modelo: \(currentModelName ?? "Desconocido")
        • Inputs: \(description.inputDescriptionsByName.keys)
        • Outputs: \(description.outputDescriptionsByName.keys)
        • Señas: \(supportedSigns)
        """)
        
        // Mostrar detalles de inputs
        for (name, inputDesc) in description.inputDescriptionsByName {
            print("   Input '\(name)': \(inputDesc.type)")
            if let constraint = inputDesc.multiArrayConstraint {
                print("     Shape: \(constraint.shape)")
            }
        }
        
        // Mostrar detalles de outputs
        for (name, outputDesc) in description.outputDescriptionsByName {
            print("   Output '\(name)': \(outputDesc.type)")
            if outputDesc.type == .dictionary {
                print("     ✅ Es un diccionario (probabilidades)")
            } else if outputDesc.type == .string {
                print("     ✅ Es string (classLabel)")
            }
        }
    }
    
    /// Simula una predicción para testing
    func simulatePrediction() -> SignPrediction {
        return SignPrediction(
            id: UUID(),
            sign: "Hola",
            confidence: 0.85,
            alternativePredictions: ["Adios", "Gracias", "Por Favor"],
            timestamp: Date()
        )
    }
}
