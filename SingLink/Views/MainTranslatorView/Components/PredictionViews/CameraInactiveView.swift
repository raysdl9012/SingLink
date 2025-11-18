//
//  CameraInactiveView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

/// Vista que se muestra cuando la cámara está inactiva
struct CameraInactiveView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icono de cámara
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.7))
            
            // Texto informativo
            VStack(spacing: 8) {
                Text("Cámara Inactiva")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Presiona el botón de reproducir para comenzar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    CameraInactiveView()
}
