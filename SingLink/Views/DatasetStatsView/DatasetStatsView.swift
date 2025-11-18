//
//  DatasetStatsView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI
internal import Combine

struct DatasetStatsView: View {
    @ObservedObject var dataService = DataCollectionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportSheet = false
    @State private var exportedURL: URL?
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard
                    
                    // Progress Card
                    progressCard
                    
                    // Statistics Card
                    statisticsCard
                    
                    // Labels Distribution
                    distributionCard
                    
                    // Data Preview
                    dataPreviewCard
                    
                    // Actions
                    actionsCard
                    
                    // Session Info
                    sessionCard
                }
                .padding()
            }
            .navigationTitle("Dataset Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Clear All Training Data", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All Data", role: .destructive) {
                    dataService.clearAllData()
                }
            } message: {
                VStack {
                    Text("This will permanently delete:")
                    Text("• \(dataService.totalSamplesCollected) total samples")
                    Text("• \(dataService.getDatasetStats().uniqueLabels) unique signs")
                    Text("This action cannot be undone.")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Data Collection Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Recording Indicator
                if dataService.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("REC")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                StatItem(
                    value: "\(dataService.totalSamplesCollected)",
                    label: "Total Samples",
                    icon: "number.circle.fill",
                    color: .green
                )
                
                StatItem(
                    value: "\(dataService.currentSessionSamples.count)",
                    label: "This Session",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatItem(
                    value: dataService.isRecording ? "Yes" : "No",
                    label: "Recording",
                    icon: "record.circle.fill",
                    color: dataService.isRecording ? .red : .gray
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                
                Text("Collection Progress")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended for Training:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ProgressView(value: Double(dataService.totalSamplesCollected), total: 500)
                    .progressViewStyle(LinearProgressViewStyle(tint: getProgressColor()))
                
                HStack {
                    Text("\(dataService.totalSamplesCollected) / 500 samples")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(Double(dataService.totalSamplesCollected) / 500 * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if dataService.totalSamplesCollected < 100 {
                    Text("🎯 Goal: Collect at least 100 samples per sign")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if dataService.totalSamplesCollected < 300 {
                    Text("✅ Good progress! Aim for 300+ samples for better accuracy")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("🎉 Excellent! You have enough data for training")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.purple)
                
                Text("Dataset Statistics")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            let stats = dataService.getDatasetStats()
            
            if stats.totalSamples == 0 {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No Data Collected Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Start recording signs using the main screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(title: "Total Samples", value: "\(stats.totalSamples)")
                    StatRow(title: "Unique Labels", value: "\(stats.uniqueLabels)")
                    StatRow(title: "Dataset Balance", value: stats.isBalanced ? "✅ Balanced" : "⚠️ Imbalanced")
                    
                    if stats.totalSamples > 0 {
                        Text("Label Distribution:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 4)
                        
                        ForEach(Array(stats.labelDistribution.keys.sorted()), id: \.self) { label in
                            if let percentage = stats.labelDistribution[label] {
                                DistributionRow(
                                    label: label,
                                    count: stats.samplesPerLabel[label] ?? 0,
                                    percentage: percentage
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.green)
                
                Text("Labels Overview")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            let stats = dataService.getDatasetStats()
            let sortedLabels = stats.samplesPerLabel.keys.sorted()
            
            if sortedLabels.isEmpty {
                Text("No labels collected yet")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(sortedLabels, id: \.self) { label in
                    HStack {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(stats.samplesPerLabel[label] ?? 0) samples")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    
                    if stats.samplesPerLabel[label] ?? 0 < 50 {
                        Text("⚠️ Collect more samples for better accuracy")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var dataPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                
                Text("Data Preview")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            if let firstSample = dataService.getAllSamples().first {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sample Structure:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Label: \"\(firstSample.label)\"")
                        .font(.caption)
                    
                    Text("Points: \(firstSample.handPose.points.count) joints")
                        .font(.caption)
                    
                    Text("Confidence: \(String(format: "%.2f", firstSample.confidence))")
                        .font(.caption)
                    
                    Text("Timestamp: \(firstSample.timestamp, formatter: dateFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Session: \(firstSample.sessionId.prefix(8))...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No samples to preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var actionsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.blue)
                
                Text("Actions")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 12) {
                // Export Button
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Training Data (CSV)")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                }
                
                Divider()
                
                // Clear Data Button
                Button(action: { showingClearAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Data")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                
                Text("Session Info")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                if dataService.isRecording {
                    Text("Session ID: \(dataService.currentSessionId)")
                        .font(.caption)
                        .textSelection(.enabled)
                    
                    Text("Started: \(Date(), formatter: dateFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                     
                    Text("Samples this session: \(dataService.currentSessionSamples.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No active recording session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func exportData() {
        if let url = dataService.exportForCreateMLToCSV() {
            exportedURL = url
            showingExportSheet = true
        }
    }
    
    private func getProgressColor() -> Color {
        let progress = Double(dataService.totalSamplesCollected) / 500.0
        switch progress {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        default: return .green
        }
    }
}

// Supporting Views
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct DistributionRow: View {
    let label: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(count) (\(String(format: "%.1f", percentage))%)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: percentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    DatasetStatsView()
}
