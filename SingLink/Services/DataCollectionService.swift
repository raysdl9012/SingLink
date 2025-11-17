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
    
    private init() {
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
        
        // ✅ CORRECCIÓN: Guardar ANTES de mostrar el mensaje
        let samplesCollected = currentSessionSamples.count
        
        if samplesCollected > 0 {
            saveSessionSamples()
            print("⏹️ Stopped data collection session. Collected \(samplesCollected) samples")
        } else {
            print("⏹️ Stopped data collection session. No samples collected")
        }
        
        // ✅ CORRECCIÓN: Limpiar después de guardar
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
    
    func exportTrainingData() -> URL? {
        let allSamples = getAllSamples()
        
        guard !allSamples.isEmpty else {
            print("❌ No hay datos para exportar")
            return nil
        }
        
        let csvString = convertSamplesToCSV(samples: allSamples)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("signlink_training_\(Date().formatted(date: .numeric, time: .shortened)).csv")
        print("File path: \(fileURL.path)")
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("📤 Exported \(allSamples.count) samples to: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ Error exporting training data: \(error)")
            return nil
        }
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
    
    // ✅ NUEVO: Método para debug detallado
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
    
    private func getAllSamples() -> [TrainingSample] {
        return allStoredSamples + currentSessionSamples
    }
    
    private func convertSamplesToCSV(samples: [TrainingSample]) -> String {
        var csvString = "label,timestamp,session_id,"
        
        // CSV header - dynamic based on hand points
        if let firstSample = samples.first {
            for i in 0..<firstSample.handPose.points.count {
                csvString += "point_\(i)_x,point_\(i)_y,point_\(i)_confidence,"
            }
            // Remove last comma
            csvString = String(csvString.dropLast())
        }
        csvString += "\n"
        
        // CSV data
        for sample in samples {
            var row = "\"\(sample.label)\",\(sample.timestamp.timeIntervalSince1970),\(sample.sessionId),"
            
            for point in sample.handPose.points {
                row += "\(point.x),\(point.y),\(point.confidence),"
            }
            
            // Remove last comma and add newline
            row = String(row.dropLast()) + "\n"
            csvString += row
        }
        
        return csvString
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
