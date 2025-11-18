//
//  HeaderView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

/// Header de la aplicación con botones de navegación y estado
struct HeaderView: View {
    @Binding var showingHistory: Bool
    @Binding var showingSettings: Bool
    @Binding var showingStats: Bool
    
    let dataCollectionService: DataCollectionService
    let currentDataLabel: String
    let onDataCollectionTapped: () -> Void
    
    var body: some View {
        HStack {
            // Botón historial
            HeaderButton(icon: "clock.arrow.circlepath") {
                showingHistory = true
            }
            
            Spacer()
            
            // Título y estado
            VStack(spacing: 4) {
                Text("SignLink")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Indicador de data collection
                if dataCollectionService.isRecording {
                    recordingIndicator
                }
            }
            
            Spacer()
            
            // Botones de acción derecha
            HStack(spacing: 12) {
                // Botón data collection
                HeaderButton(
                    icon: dataCollectionService.isRecording ? "record.circle.fill" : "record.circle",
                    action: onDataCollectionTapped
                )
                .foregroundColor(dataCollectionService.isRecording ? .red : .white)
                
                // Botón estadísticas
                HeaderButton(icon: "chart.bar.fill") {
                    showingStats = true
                }
                
                // Botón configuración
                HeaderButton(icon: "gearshape") {
                    showingSettings = true
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .padding(.bottom, 10)
        .background(.black.opacity(0.3))
    }
    
    private var recordingIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            
            Text("Grabando: \(currentDataLabel)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    HeaderView(showingHistory: .constant(false),
               showingSettings: .constant(false),
               showingStats: .constant(false),
               dataCollectionService: DataCollectionService(),
               currentDataLabel: "DataLabel") {
        
    }
}
