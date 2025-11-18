//
//  MLPreprocessor.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Utils/MLPreprocessor.swift
import Foundation
import CoreML

final class MLPreprocessor {
    
    // MARK: - Hand Pose to MLMultiArray Conversion
    static func convertHandPoseToMLMultiArray(_ handPose: HandPose) -> MLMultiArray? {
        let pointCount = handPose.points.count
        let featuresPerPoint = 3 // x, y, confidence
        
        do {
            let array = try MLMultiArray(
                shape: [1, NSNumber(value: pointCount * featuresPerPoint)],
                dataType: .double
            )
            
            for (index, point) in handPose.points.enumerated() {
                let baseIndex = index * featuresPerPoint
                array[baseIndex] = NSNumber(value: point.x)        // x coordinate
                array[baseIndex + 1] = NSNumber(value: point.y)    // y coordinate
                array[baseIndex + 2] = NSNumber(value: Double(point.confidence)) // confidence
            }
            
            return array
            
        } catch {
            print("❌ Error creating MLMultiArray: \(error)")
            return nil
        }
    }
    
    static func convertHandPosesToBatchMLMultiArray(_ handPoses: [HandPose]) -> MLMultiArray? {
        guard !handPoses.isEmpty else { return nil }
        
        let pointCount = handPoses[0].points.count
        let featuresPerPoint = 3
        let batchSize = handPoses.count
        let featuresPerSample = pointCount * featuresPerPoint
        
        do {
            let array = try MLMultiArray(
                shape: [NSNumber(value: batchSize), NSNumber(value: featuresPerSample)],
                dataType: .double
            )
            
            for (sampleIndex, handPose) in handPoses.enumerated() {
                for (pointIndex, point) in handPose.points.enumerated() {
                    let baseIndex = sampleIndex * featuresPerSample + pointIndex * featuresPerPoint
                    array[baseIndex] = NSNumber(value: point.x)
                    array[baseIndex + 1] = NSNumber(value: point.y)
                    array[baseIndex + 2] = NSNumber(value: Double(point.confidence))
                }
            }
            
            return array
            
        } catch {
            print("❌ Error creating batch MLMultiArray: \(error)")
            return nil
        }
    }
    
    // MARK: - Normalization
    static func normalizeHandPose(_ handPose: HandPose) -> HandPose {
        let points = handPose.points
        
        guard !points.isEmpty else { return handPose }
        
        // Find bounding box of hand points
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 1
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 1
        
        let scaleX = max(maxX - minX, 0.001) // Avoid division by zero
        let scaleY = max(maxY - minY, 0.001)
        
        let normalizedPoints = points.map { point in
            SimulatedPoint(
                x: (point.x - minX) / scaleX,
                y: (point.y - minY) / scaleY,
                confidence: point.confidence,
                jointName: point.jointName
            )
        }
        
        return HandPose(
            points: normalizedPoints,
            confidence: handPose.confidence,
            timestamp: handPose.timestamp
        )
    }
    
    // MARK: - Data Augmentation
    static func augmentHandPose(_ handPose: HandPose, augmentations: Int = 3) -> [HandPose] {
        var augmentedPoses: [HandPose] = [handPose]
        
        for i in 0..<augmentations {
            if let augmented = applyRandomAugmentation(handPose, iteration: i) {
                augmentedPoses.append(augmented)
            }
        }
        
        return augmentedPoses
    }
    
    private static func applyRandomAugmentation(_ handPose: HandPose, iteration: Int) -> HandPose? {
        let augmentationType = iteration % 3
        
        switch augmentationType {
        case 0:
            return applySmallRotation(handPose, angle: Double.random(in: -0.15...0.15))
        case 1:
            return applySmallTranslation(handPose, dx: Double.random(in: -0.1...0.1), dy: Double.random(in: -0.1...0.1))
        case 2:
            return applySmallScale(handPose, scale: Double.random(in: 0.8...1.2))
        default:
            return nil
        }
    }
    
    private static func applySmallRotation(_ handPose: HandPose, angle: Double) -> HandPose? {
        let points = handPose.points
        guard !points.isEmpty else { return nil }
        
        let centerX = points.map { $0.x }.reduce(0, +) / Double(points.count)
        let centerY = points.map { $0.y }.reduce(0, +) / Double(points.count)
        
        let rotatedPoints = points.map { point in
            let dx = point.x - centerX
            let dy = point.y - centerY
            
            let newX = centerX + dx * cos(angle) - dy * sin(angle)
            let newY = centerY + dx * sin(angle) + dy * cos(angle)
            
            return SimulatedPoint(
                x: max(0, min(1, newX)), // Clamp to 0-1 range
                y: max(0, min(1, newY)),
                confidence: point.confidence,
                jointName: point.jointName
            )
        }
        
        return HandPose(
            points: rotatedPoints,
            confidence: handPose.confidence,
            timestamp: handPose.timestamp
        )
    }
    
    private static func applySmallTranslation(_ handPose: HandPose, dx: Double, dy: Double) -> HandPose? {
        let translatedPoints = handPose.points.map { point in
            SimulatedPoint(
                x: max(0, min(1, point.x + dx)),
                y: max(0, min(1, point.y + dy)),
                confidence: point.confidence,
                jointName: point.jointName
            )
        }
        
        return HandPose(
            points: translatedPoints,
            confidence: handPose.confidence,
            timestamp: handPose.timestamp
        )
    }
    
    private static func applySmallScale(_ handPose: HandPose, scale: Double) -> HandPose? {
        let points = handPose.points
        guard !points.isEmpty else { return nil }
        
        let centerX = points.map { $0.x }.reduce(0, +) / Double(points.count)
        let centerY = points.map { $0.y }.reduce(0, +) / Double(points.count)
        
        let scaledPoints = points.map { point in
            let dx = point.x - centerX
            let dy = point.y - centerY
            
            let newX = centerX + dx * scale
            let newY = centerY + dy * scale
            
            return SimulatedPoint(
                x: max(0, min(1, newX)),
                y: max(0, min(1, newY)),
                confidence: point.confidence,
                jointName: point.jointName
            )
        }
        
        return HandPose(
            points: scaledPoints,
            confidence: handPose.confidence,
            timestamp: handPose.timestamp
        )
    }
    
    // MARK: - Feature Engineering
    static func extractFeatures(from handPose: HandPose) -> [String: Double] {
        let points = handPose.points
        guard !points.isEmpty else { return [:] }
        
        var features: [String: Double] = [:]
        
        // Basic statistics
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let confidences = points.map { Double($0.confidence) }
        
        features["mean_x"] = xs.reduce(0, +) / Double(xs.count)
        features["mean_y"] = ys.reduce(0, +) / Double(ys.count)
        features["std_x"] = standardDeviation(xs)
        features["std_y"] = standardDeviation(ys)
        features["confidence_avg"] = confidences.reduce(0, +) / Double(confidences.count)
        
        // Bounding box features
        features["width"] = (xs.max() ?? 0) - (xs.min() ?? 0)
        features["height"] = (ys.max() ?? 0) - (ys.min() ?? 0)
        features["aspect_ratio"] = features["width"]! / max(features["height"]!, 0.001)
        
        // Center of mass
        features["com_x"] = features["mean_x"]
        features["com_y"] = features["mean_y"]
        
        return features
    }
    
    private static func standardDeviation(_ array: [Double]) -> Double {
        let length = Double(array.count)
        let avg = array.reduce(0, +) / length
        let sumOfSquaredDiffs = array.map { pow($0 - avg, 2) }.reduce(0, +)
        return sqrt(sumOfSquaredDiffs / length)
    }
    
    // MARK: - Data Validation
    static func validateHandPose(_ handPose: HandPose) -> Bool {
        let points = handPose.points
        
        // Check if we have reasonable number of points
        guard points.count >= 5 else {
            print("❌ Too few points: \(points.count)")
            return false
        }
        
        // Check confidence levels
        let avgConfidence = points.map { $0.confidence }.reduce(0, +) / Float(points.count)
        guard avgConfidence > 0.3 else {
            print("❌ Low average confidence: \(avgConfidence)")
            return false
        }
        
        // Check if points are within valid range
        for point in points {
            guard point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1 else {
                print("❌ Point out of bounds: (\(point.x), \(point.y))")
                return false
            }
        }
        
        return true
    }
}

// AGREGAR al final de MLPreprocessor.swift
extension MLPreprocessor {
    
    // MARK: - Inference Preparation
    
    /// Prepara una hand pose para inferencia, aplicando la misma normalización que en entrenamiento
    static func prepareForInference(_ handPose: HandPose) -> HandPose {
        // Aplicar normalización consistente con el entrenamiento
        let normalizedPose = normalizeHandPose(handPose)
        
        // Aquí puedes agregar más preprocesamiento específico para inferencia
        // como filtrado de outliers, suavizado, etc.
        
        return normalizedPose
    }
    
    /// Valida si una hand pose es adecuada para inferencia
    static func isValidForInference(_ handPose: HandPose) -> Bool {
        let points = handPose.points
        
        // Verificar que tenemos suficientes puntos
        guard points.count >= 15 else {
            return false
        }
        
        // Verificar confianza promedio
        let avgConfidence = points.map { $0.confidence }.reduce(0, +) / Float(points.count)
        guard avgConfidence > 0.4 else {
            return false
        }
        
        // Verificar que los puntos están en rango válido
        for point in points {
            guard point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1 else {
                return false
            }
        }
        
        return true
    }
}
