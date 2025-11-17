//
//  AboutView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Views/AboutView.swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Logo/Icono
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("SignLink")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Traductor de Lenguaje de Señas")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Descripción
                VStack(alignment: .leading, spacing: 16) {
                    Text("Acerca de SignLink")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("SignLink es una aplicación diseñada para facilitar la comunicación entre personas sordas y oyentes mediante el uso de inteligencia artificial para traducir el lenguaje de señas en tiempo real.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(.horizontal)
                
                // Características
                VStack(alignment: .leading, spacing: 16) {
                    Text("Características")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    FeatureRow(icon: "camera.fill", text: "Detección en tiempo real")
                    FeatureRow(icon: "text.bubble.fill", text: "Traducción instantánea")
                    FeatureRow(icon: "clock.arrow.circlepath", text: "Historial de conversaciones")
                    FeatureRow(icon: "hand.raised.fill", text: "Múltiples lenguajes de señas")
                }
                .padding(.horizontal)
                
                // Información técnica
                VStack(alignment: .leading, spacing: 12) {
                    Text("Información Técnica")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    InfoRow(title: "Versión", value: "1.0.0")
                    InfoRow(title: "Desarrollado con", value: "SwiftUI & Core ML")
                    InfoRow(title: "Compatibilidad", value: "iOS 16.0+")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("Hecho con ❤️ para una comunicación más inclusiva")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AboutView()
}

#Preview {
    AboutView()
}
