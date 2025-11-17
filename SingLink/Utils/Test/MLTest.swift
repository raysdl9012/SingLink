// Utils/MLTest.swift - Versión Corregida
import Foundation

class MLTest {
    static func testDataCollection() {
        let dataService = DataCollectionService.shared
        
        print("🧪 Testing Data Collection Service...")
        
        // Test starting session
        dataService.startRecordingSession()
        assert(dataService.isRecording, "Session should be recording")
        
        // USAR LA MISMA FUNCIÓN QUE CAMERA MANAGER - 21 PUNTOS
        let testPoints = generateRealisticHandPoints()
        let testHandPose = HandPose(points: testPoints, confidence: 0.85)
        
        // DEBUG: Verificar la validación
        print("🔍 Validation Check:")
        print("• Points count: \(testHandPose.points.count)")
        print("• Avg confidence: \(testHandPose.points.map { $0.confidence }.reduce(0, +) / Float(testHandPose.points.count))")
        
        let isValid = MLPreprocessor.validateHandPose(testHandPose)
        print("• Is valid: \(isValid)")
        
        // Test recording sample
        dataService.recordSample(handPose: testHandPose, label: "Hola")
        assert(dataService.currentSessionSamples.count == 1, "Should have 1 sample")
        
        // Test ML preprocessing
        let normalizedPose = MLPreprocessor.normalizeHandPose(testHandPose)
        assert(!normalizedPose.points.isEmpty, "Normalized pose should have points")
        
        let mlArray = MLPreprocessor.convertHandPoseToMLMultiArray(normalizedPose)
        assert(mlArray != nil, "Should create MLMultiArray")
        
        // Test data augmentation
        let augmentedPoses = MLPreprocessor.augmentHandPose(testHandPose)
        assert(augmentedPoses.count > 1, "Should generate augmented poses")
        
        // Test validation - ESTO DEBERÍA PASAR AHORA
        assert(isValid, "Hand pose should be valid")
        
        // Stop session
        dataService.stopRecordingSession()
        assert(!dataService.isRecording, "Session should not be recording")
        
        print("✅ All ML tests passed!")
        
        // Print stats
        let stats = dataService.getDatasetStats()
        print(stats.description)
    }
    
    // USAR LA MISMA FUNCIÓN QUE CAMERA MANAGER
    private static func generateRealisticHandPoints() -> [SimulatedPoint] {
        let jointNames = [
            "wrist", "thumbCMC", "thumbMP", "thumbIP", "thumbTip",
            "indexMCP", "indexPIP", "indexDIP", "indexTip",
            "middleMCP", "middlePIP", "middleDIP", "middleTip",
            "ringMCP", "ringPIP", "ringDIP", "ringTip",
            "littleMCP", "littlePIP", "littleDIP", "littleTip"
        ]
        
        var points: [SimulatedPoint] = []
        
        let baseX: Double = 0.5
        let baseY: Double = 0.5
        
        for jointName in jointNames {
            let x = baseX + Double.random(in: -0.1...0.1)
            let y = baseY + Double.random(in: -0.1...0.1)
            let confidence = Float.random(in: 0.7...0.98)
            
            let point = SimulatedPoint(
                x: max(0.1, min(0.9, x)),
                y: max(0.1, min(0.9, y)),
                confidence: confidence,
                jointName: jointName
            )
            points.append(point)
        }
        
        return points
    }
}
