//
//  PerformanceDebugView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct PerformanceDebugView: View {
    @ObservedObject var monitor = PerformanceMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Debug")
                .font(.headline)
            
            HStack {
                Text("FPS: \(String(format: "%.1f", monitor.currentFPS))")
                Spacer()
                Text(monitor.memoryUsage)
            }
            .font(.caption)
            .monospaced()
            
            HStack {
                Text("Thermal: \(monitor.thermalState.description)")
                Spacer()
                Text("Battery: \(monitor.batteryImpact.description)")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .foregroundColor(.white)
        
        
    }
}



#Preview {
    PerformanceDebugView()
}
