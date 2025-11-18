//
//  StatusView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI
internal import AVFoundation

/// Vista de estado del sistema
struct StatusView: View {
    let cameraManager: CameraManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Indicadores de estado
            HStack(spacing: 12) {
                StatusIndicator(
                    title: "Cámara",
                    isActive: cameraManager.isSessionRunning,
                    authorized: cameraManager.isAuthorized
                )
                
                StatusIndicator(
                    title: cameraManager.currentCameraPosition == .front ? "Frontal" : "Trasera",
                    isActive: true,
                    authorized: true
                )
                
                StatusIndicator(
                    title: "Detección",
                    isActive: true,
                    authorized: true
                )
            }
            
            // Mensaje de advertencia si no hay permisos
            if !cameraManager.isAuthorized {
                Text("Se requiere permiso de cámara")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// Indicador individual de estado
struct StatusIndicator: View {
    let title: String
    let isActive: Bool
    let authorized: Bool
    
    private var color: Color {
        if !authorized {
            return .red
        }
        return isActive ? .green : .orange
    }
    
    private var icon: String {
        if !authorized {
            return "xmark.circle.fill"
        }
        return isActive ? "checkmark.circle.fill" : "pause.circle.fill"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }
}

#Preview {
    StatusView(cameraManager: CameraManager())
}
