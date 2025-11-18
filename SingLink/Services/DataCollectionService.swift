//
//  DataCollectionService.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation
internal import Combine

struct TrainingSample: Codable, Identifiable {
    let id: UUID
    let handPose: HandPose
    let label: String
    let timestamp: Date
    let confidence: Float
    let sessionId: String
    
    init(id: UUID = UUID(), handPose: HandPose, label: String, timestamp: Date = Date(), confidence: Float = 1.0, sessionId: String = UUID().uuidString) {
        self.id = id
        self.handPose = handPose
        self.label = label
        self.timestamp = timestamp
        self.confidence = confidence
        self.sessionId = sessionId
    }
}

@MainActor
final class DataCollectionService: ObservableObject {
    static let shared = DataCollectionService()
    
    @Published var isRecording = false
    @Published var currentSessionSamples: [TrainingSample] = []
    @Published var totalSamplesCollected = 0
    @Published var currentSessionId: String = ""
    
    private let fileManager = FileManager.default
    private let samplesKey = "signlink_collected_samples"
    private var allStoredSamples: [TrainingSample] = []
    
    init() {
        loadExistingSamples()
        totalSamplesCollected = allStoredSamples.count + currentSessionSamples.count
    }
    
    // MARK: - Public Methods
    func startRecordingSession() {
        isRecording = true
        currentSessionSamples.removeAll()
        currentSessionId = UUID().uuidString
        print("🎬 Started data collection session: \(currentSessionId)")
    }
    
    func stopRecordingSession() {
        isRecording = false
        
        let samplesCollected = currentSessionSamples.count
        if samplesCollected > 0 {
            saveSessionSamples()
            print("⏹️ Stopped data collection session. Collected \(samplesCollected) samples")
        } else {
            print("⏹️ Stopped data collection session. No samples collected")
        }
        
        currentSessionSamples.removeAll()
        currentSessionId = ""
    }
    
    func recordSample(handPose: HandPose, label: String, confidence: Float = 1.0) {
        guard isRecording else {
            print("❌ Cannot record sample - not recording")
            return
        }
        
        let sample = TrainingSample(
            handPose: handPose,
            label: label,
            confidence: confidence,
            sessionId: currentSessionId
        )
        
        currentSessionSamples.append(sample)
        totalSamplesCollected = allStoredSamples.count + currentSessionSamples.count
        
        print("📝 Recorded sample for: '\(label)' - Session: \(currentSessionSamples.count) - Total: \(totalSamplesCollected)")
    }
    
    func exportForCreateML() -> URL? {
        let allSamples = getAllSamples()
        
        guard !allSamples.isEmpty else {
            print("❌ No hay datos para exportar")
            return nil
        }
        
        print("🔄 Procesando \(allSamples.count) muestras para Create ML...")
        
        // Generar JSON en lugar de CSV
        let jsonData = generateCreateMLJSON(samples: allSamples)
        
        // Guardar como .json
        guard let fileURL = saveJSONToDocuments(jsonData: jsonData, samples: allSamples) else {
            return nil
        }
        
        print("✅ Exportación JSON completada exitosamente")
        return fileURL
    }
    
    // MARK: - Export Methods for Create ML
    func exportForCreateMLToCSV() -> URL? {
        let allSamples = getAllSamples()
        
        guard !allSamples.isEmpty else {
            print("❌ No hay datos para exportar")
            return nil
        }
        
        print("🔄 Procesando \(allSamples.count) muestras para Create ML...")
        
        // Limpiar y validar datos
        let validSamples = cleanSamples(allSamples)
        
        guard !validSamples.isEmpty else {
            print("❌ No hay muestras válidas después de la limpieza")
            return nil
        }
        
        // Generar CSV
        let csvString = generateCreateMLCSV(samples: validSamples)
        
        // Guardar en Documents (compartible)
        guard let fileURL = saveCSVToDocuments(csvString: csvString, samples: validSamples) else {
            return nil
        }
        
        print("✅ Exportación completada exitosamente")
        return fileURL
    }
    
    func getDatasetStats() -> DatasetStatistics {
        let allSamples = getAllSamples()
        let labels = Set(allSamples.map { $0.label })
        let samplesPerLabel = Dictionary(grouping: allSamples, by: { $0.label })
            .mapValues { $0.count }
        
        return DatasetStatistics(
            totalSamples: allSamples.count,
            uniqueLabels: labels.count,
            samplesPerLabel: samplesPerLabel,
            labelDistribution: calculateLabelDistribution(samplesPerLabel: samplesPerLabel),
            isBalanced: checkBalance(samplesPerLabel: samplesPerLabel)
        )
    }
    
    func clearAllData() {
        allStoredSamples.removeAll()
        currentSessionSamples.removeAll()
        totalSamplesCollected = 0
        UserDefaults.standard.removeObject(forKey: samplesKey)
        print("🗑️ Cleared all training data")
    }
    
    func printDebugInfo() {
        print("""
        🔍 DATA COLLECTION DEBUG:
        • isRecording: \(isRecording)
        • currentSessionId: \(currentSessionId)
        • currentSessionSamples: \(currentSessionSamples.count)
        • allStoredSamples: \(allStoredSamples.count)
        • totalSamplesCollected: \(totalSamplesCollected)
        • getAllSamples().count: \(getAllSamples().count)
        """)
    }
    
    // MARK: - Private Methods
    private func loadExistingSamples() {
        guard let data = UserDefaults.standard.data(forKey: samplesKey) else {
            allStoredSamples = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            allStoredSamples = try decoder.decode([TrainingSample].self, from: data)
            print("📥 Loaded \(allStoredSamples.count) existing samples")
        } catch {
            print("❌ Error loading existing samples: \(error)")
            allStoredSamples = []
        }
    }
    
    private func saveSessionSamples() {
        guard !currentSessionSamples.isEmpty else {
            print("💾 No samples to save in current session")
            return
        }
        
        let samplesToSave = currentSessionSamples.count
        allStoredSamples.append(contentsOf: currentSessionSamples)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allStoredSamples)
            UserDefaults.standard.set(data, forKey: samplesKey)
            print("💾 Saved \(samplesToSave) new samples to persistent storage")
        } catch {
            print("❌ Error saving samples: \(error)")
        }
    }
    
    public func getAllSamples() -> [TrainingSample] {
        return allStoredSamples + currentSessionSamples
    }
    
    // MARK: - Create ML Data Processing
    private func cleanSamples(_ samples: [TrainingSample]) -> [TrainingSample] {
        var validSamples: [TrainingSample] = []
        var skippedCount = 0
        
        for sample in samples {
            // Verificar que tenga suficientes puntos válidos
            let validPoints = sample.handPose.points.filter { point in
                point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1
            }
            
            if validPoints.count >= 10 { // Mínimo 10 puntos válidos
                validSamples.append(sample)
            } else {
                skippedCount += 1
            }
        }
        
        if skippedCount > 0 {
            print("⚠️ Se omitieron \(skippedCount) muestras por datos insuficientes")
        }
        
        return validSamples
    }
    
    

    private func generateCreateMLJSON(samples: [TrainingSample]) -> Data {
        var jsonArray: [[String: Any]] = []
        
        for sample in samples {
            let poseDict = convertToCreateMLFormat(handPose: sample.handPose)
            let sampleDict: [String: Any] = [
                "label": sample.label,
                "pose": poseDict
            ]
            jsonArray.append(sampleDict)
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted])
            return jsonData
        } catch {
            print("❌ Error creating JSON: \(error)")
            return Data()
        }
    }

    private func convertToCreateMLFormat(handPose: HandPose) -> [String: Any] {
        var pointsArray: [[String: Double]] = []
        
        for point in handPose.points {
            let normalizedPoint: [String: Double] = [
                "x": max(0.0, min(1.0, point.x)),
                "y": max(0.0, min(1.0, point.y))
            ]
            pointsArray.append(normalizedPoint)
        }
        
        // Asegurar 21 puntos
        while pointsArray.count < 21 {
            pointsArray.append(["x": 0.0, "y": 0.0])
        }
        
        return [
            "points": pointsArray,
            "frame": [
                "width": 1.0,
                "height": 1.0
            ]
        ]
    }

    private func saveJSONToDocuments(jsonData: Data, samples: [TrainingSample]) -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ No se pudo acceder al directorio Documents")
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        // ✅ EXTENSIÓN .json
        let fileName = "SignLink_Training_\(dateString).json"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try jsonData.write(to: fileURL)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                printStats(samples: samples, fileURL: fileURL)
                return fileURL
            } else {
                print("❌ El archivo JSON no se creó correctamente")
                return nil
            }
        } catch {
            print("❌ Error guardando JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    private func generateCreateMLCSV(samples: [TrainingSample]) -> String {
        // Create ML puede requerir nombres de columnas específicos
        var csvString = "label,"
        
        // Agregar columnas para cada punto
        for i in 0..<21 {
            csvString += "point_\(i).x,point_\(i).y"
            if i < 20 { csvString += "," }
        }
        csvString += "\n"
        
        // Datos
        for sample in samples {
            var row = escapeCSVField(sample.label)
            
            for i in 0..<21 {
                if i < sample.handPose.points.count {
                    let point = sample.handPose.points[i]
                    let x = max(0.0, min(1.0, point.x))
                    let y = max(0.0, min(1.0, point.y))
                    row += ",\(x),\(y)"
                } else {
                    row += ",0.0,0.0"
                }
            }
            csvString += row + "\n"
        }    
        return csvString
    }
    
    private func saveCSVToDocuments(csvString: String, samples: [TrainingSample]) -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ No se pudo acceder al directorio Documents")
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "SignLink_CreateML_\(dateString).csv"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Verificar creación
            if fileManager.fileExists(atPath: fileURL.path) {
                printStats(samples: samples, fileURL: fileURL)
                return fileURL
            } else {
                print("❌ El archivo no se creó correctamente")
                return nil
            }
        } catch {
            print("❌ Error guardando CSV: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func printStats(samples: [TrainingSample], fileURL: URL) {
        let labels = Set(samples.map { $0.label })
        let distribution = Dictionary(grouping: samples, by: { $0.label })
            .mapValues { $0.count }
        
        print("""
        ✅ ARCHIVO CREADO EXITOSAMENTE:
        📁 Ubicación: \(fileURL.lastPathComponent)
        📊 Estadísticas:
          • Muestras totales: \(samples.count)
          • Labels únicos: \(labels.count)
          • Distribución:
        \(distribution.map { "    - \($0.key): \($0.value) muestras" }.joined(separator: "\n"))
        """)
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    private func calculateLabelDistribution(samplesPerLabel: [String: Int]) -> [String: Double] {
        let total = Double(samplesPerLabel.values.reduce(0, +))
        guard total > 0 else { return [:] }
        return samplesPerLabel.mapValues { Double($0) / total * 100.0 }
    }
    
    private func checkBalance(samplesPerLabel: [String: Int]) -> Bool {
        guard let max = samplesPerLabel.values.max(),
              let min = samplesPerLabel.values.min(),
              max > 0 else { return false }
        return Double(min) / Double(max) > 0.5
    }
}

struct DatasetStatistics {
    let totalSamples: Int
    let uniqueLabels: Int
    let samplesPerLabel: [String: Int]
    let labelDistribution: [String: Double]
    let isBalanced: Bool
    
    var description: String {
        """
        📊 Dataset Statistics:
        • Total Samples: \(totalSamples)
        • Unique Labels: \(uniqueLabels)
        • Balanced: \(isBalanced ? "✅" : "⚠️")
        • Distribution: \(labelDistribution.map { "\($0.key): \(String(format: "%.1f", $0.value))%" }.joined(separator: ", "))
        """
    }
}
