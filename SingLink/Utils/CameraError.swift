//
//  Untitled.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation

enum CameraError: LocalizedError, Identifiable, Equatable {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case permissionDenied
    case configurationError(Error)
    case sessionError(Error)
    
    var id: String {
        localizedDescription
    }
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "No se pudo acceder a la cámara del dispositivo"
        case .cannotAddInput:
            return "Error al configurar la entrada de cámara"
        case .cannotAddOutput:
            return "Error al configurar la salida de video"
        case .permissionDenied:
            return "Permiso de cámara denegado. Por favor, habilita el acceso en Configuración"
        case .configurationError(let error):
            return "Error de configuración: \(error.localizedDescription)"
        case .sessionError(let error):
            return "Error de sesión: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Ve a Configuración > SignLink y activa el permiso de cámara"
        case .deviceNotFound:
            return "Verifica que la cámara no esté siendo usada por otra aplicación"
        default:
            return "Reinicia la aplicación e intenta nuevamente"
        }
    }
    
    // Implementación de Equatable
    static func == (lhs: CameraError, rhs: CameraError) -> Bool {
        switch (lhs, rhs) {
        case (.deviceNotFound, .deviceNotFound):
            return true
        case (.cannotAddInput, .cannotAddInput):
            return true
        case (.cannotAddOutput, .cannotAddOutput):
            return true
        case (.permissionDenied, .permissionDenied):
            return true
        case (.configurationError(let lhsError), .configurationError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.sessionError(let lhsError), .sessionError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
