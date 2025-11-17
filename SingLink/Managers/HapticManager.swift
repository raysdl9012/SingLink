//
//  HapticManager.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Utils/HapticManager.swift
import UIKit
internal import Combine

final class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    @Published var isEnabled: Bool = true
    
    private init() {}
    
    // MARK: - Notification Feedback (Éxito, Error, Advertencia)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        
        print("📳 Háptico: Notificación \(type)")
    }
    
    // MARK: - Impact Feedback (Light, Medium, Heavy, Rigid, Soft)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        
        print("📳 Háptico: Impacto \(style)")
    }
    
    // MARK: - Selection Feedback (Cambios de selección)
    func selection() {
        guard isEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        
        print("📳 Háptico: Selección")
    }
    
    // MARK: - Custom Feedback para SignLink
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
    
    func cameraStarted() {
        guard isEnabled else { return }
        impact(.heavy)
    }
    
    func cameraStopped() {
        guard isEnabled else { return }
        impact(.soft)
    }
    
    func cameraSwitched() {
        guard isEnabled else { return }
        selection()
    }
    
    func deleteAction() {
        guard isEnabled else { return }
        notification(.warning)
    }
    
    func errorOccurred() {
        guard isEnabled else { return }
        notification(.error)
    }
    
    func toggleChanged() {
        guard isEnabled else { return }
        impact(.light)
    }
    
    func buttonPressed() {
        guard isEnabled else { return }
        impact(.rigid)
    }
    
    // MARK: - Control Global
    func enable() {
        isEnabled = true
    }
    
    func disable() {
        isEnabled = false
    }
    
    func toggle() {
        isEnabled.toggle()
    }
}
