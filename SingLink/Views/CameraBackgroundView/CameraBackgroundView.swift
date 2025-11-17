//
//  CameraBackgroundView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI


struct CameraBackgroundView: View {
    
    
    @EnvironmentObject var cameraManager: CameraManager
    
    let isActive: Bool
    
    var body: some View {
        ZStack {
            if isActive && cameraManager.isAuthorized {
                // Vista de cámara real
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
                
                // Overlay de grid para ayudar con las señas
                CameraGridView()
            } else {
                // Fondo gradiente cuando la cámara está inactiva
                inactiveCameraView
            }
        }
    }
    
    private var inactiveCameraView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Cámara Inactiva")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if !cameraManager.isAuthorized {
                    Text("Permiso de cámara requerido")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct CameraGridView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let spacing: CGFloat = 80
                
                // Líneas verticales
                for x in stride(from: 0, through: width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                // Líneas horizontales
                for y in stride(from: 0, through: height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                
                // Círculo central para guía
                let center = CGPoint(x: width / 2, y: height / 2)
                let circleRadius: CGFloat = 60
                path.addArc(center: center, radius: circleRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
            }
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    CameraBackgroundView(isActive: false)
        .environmentObject(CameraManager())
}
