//
//  HapticManager.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import UIKit
internal import Combine

/**
 Gestor centralizado de feedback háptico para SignLink.
 
 Proporciona vibraciones táctiles para diferentes interacciones de la app,
 mejorando la experiencia de usuario con retroalimentación física.
 
 - Usa `UINotificationFeedbackGenerator` para notificaciones (éxito/error/advertencia)
 - Usa `UIImpactFeedbackGenerator` para impactos (ligero/medio/fuerte)
 - Usa `UISelectionFeedbackGenerator` para cambios de selección
 */
final class HapticManager: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = HapticManager()
    
    // MARK: - Published Properties
    @Published var isEnabled: Bool = true
    
    // MARK: - Initialization
    private init() {}
}

// MARK: - Core Haptic Feedback
extension HapticManager {
    
    /// Proporciona feedback de notificación (éxito, error, advertencia)
    /// - Parameter type: Tipo de notificación háptica
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Proporciona feedback de impacto (variando intensidad)
    /// - Parameter style: Estilo de impacto háptico
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Proporciona feedback de cambio de selección
    func selection() {
        guard isEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - SignLink Specific Feedback
extension HapticManager {
    
    /// Feedback personalizado basado en la confianza de detección de señas
    /// - Parameter confidence: Nivel de confianza (0.0 - 1.0)
    func signDetected(confidence: Float) {
        guard isEnabled else { return }
        
        switch confidence {
        case 0.8...1.0:
            // Alta confianza - feedback fuerte
            notification(.success)
        case 0.6..<0.8:
            // Confianza media - feedback medio
            impact(.medium)
        default:
            // Baja confianza - feedback ligero
            impact(.light)
        }
    }
    
    /// Feedback cuando la cámara inicia
    func cameraStarted() {
        guard isEnabled else { return }
        impact(.heavy)
    }
    
    /// Feedback cuando la cámara se detiene
    func cameraStopped() {
        guard isEnabled else { return }
        impact(.soft)
    }
    
    /// Feedback cuando se cambia entre cámaras
    func cameraSwitched() {
        guard isEnabled else { return }
        selection()
    }
    
    /// Feedback para acciones destructivas (eliminar)
    func deleteAction() {
        guard isEnabled else { return }
        notification(.warning)
    }
    
    /// Feedback para errores o situaciones problemáticas
    func errorOccurred() {
        guard isEnabled else { return }
        notification(.error)
    }
    
    /// Feedback para cambios en switches/toggles
    func toggleChanged() {
        guard isEnabled else { return }
        impact(.light)
    }
    
    /// Feedback genérico para botones presionados
    func buttonPressed() {
        guard isEnabled else { return }
        impact(.rigid)
    }
}

// MARK: - Global Controls
extension HapticManager {
    
    /// Habilita todos los feedbacks hápticos
    func enable() {
        isEnabled = true
    }
    
    /// Deshabilita todos los feedbacks hápticos
    func disable() {
        isEnabled = false
    }
    
    /// Alterna el estado habilitado/deshabilitado
    func toggle() {
        isEnabled.toggle()
    }
}
