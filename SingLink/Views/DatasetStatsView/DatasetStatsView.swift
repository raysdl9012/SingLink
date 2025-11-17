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
                    
                    // Statistics Card
                    statisticsCard
                    
                    // Labels Distribution
                    distributionCard
                    
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
            .alert("Clear All Data", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    dataService.clearAllData()
                }
            } message: {
                Text("This will permanently delete all collected training data. This action cannot be undone.")
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
                }
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
        if let url = dataService.exportTrainingData() {
            exportedURL = url
            showingExportSheet = true
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
