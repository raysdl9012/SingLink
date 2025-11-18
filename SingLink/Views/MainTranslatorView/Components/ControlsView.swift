//
//  ControlsView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

/// Panel de controles para cámara y acciones
struct ControlsView: View {
    let cameraManager: CameraManager
    let isCameraActive: Bool
    let onToggleCamera: () -> Void
    let onSwitchCamera: () -> Void
    let onClearPrediction: () -> Void
    let onShowTutorial: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Botones de control principales
            HStack(spacing: 20) {
                ControlButton(
                    icon: isCameraActive ? "pause.circle.fill" : "play.circle.fill",
                    color: isCameraActive ? .red : .green,
                    action: onToggleCamera
                )
                
                // Botones adicionales solo cuando la cámara está activa
                if isCameraActive {
                    cameraActiveButtons
                }
            }
            
            // Vista de estado
            StatusView(cameraManager: cameraManager)
        }

        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
    }
    
    private var cameraActiveButtons: some View {
        Group {
            ControlButton(
                icon: "arrow.triangle.2.circlepath.camera.fill",
                color: .blue,
                action: onSwitchCamera
            )
            
            ControlButton(
                icon: "xmark.circle.fill",
                color: .orange,
                action: onClearPrediction
            )
            
            ControlButton(
                icon: "questionmark.circle.fill",
                color: .purple,
                action: onShowTutorial
            )
        }
    }
}

#Preview {
    ControlsView(cameraManager: CameraManager(), isCameraActive: false) {
        
    } onSwitchCamera: {
        
    } onClearPrediction: {
        
    } onShowTutorial: {
        
    }.background(.purple.opacity(0.4))

}
