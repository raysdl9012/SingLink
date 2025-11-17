//
//  AppSettings.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Models/AppSettings.swift
import Foundation

struct AppSettings: Codable {
    var saveHistory: Bool
    var showConfidence: Bool
    var vibrationFeedback: Bool
    var selectedLanguage: String
    var simulationMode: Bool
    
    // Valores por defecto
    static let `default` = AppSettings(
        saveHistory: true,
        showConfidence: true,
        vibrationFeedback: true,
        selectedLanguage: "LSE",
        simulationMode: true
    )
}

// Servicio para gestionar la configuración
protocol SettingsServiceProtocol {
    func saveSettings(_ settings: AppSettings) async throws
    func loadSettings() async throws -> AppSettings
    func resetToDefaults() async
}

final class SettingsService: SettingsServiceProtocol {
    private let settingsKey = "signlink_app_settings"
    private let storageQueue = DispatchQueue(label: "com.signlink.settings.storage", qos: .userInitiated)
    
    func saveSettings(_ settings: AppSettings) async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            print("❌ Error guardando configuración: \(error)")
        }
    }
    
    func loadSettings() async -> AppSettings {
            guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
                return AppSettings.default
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(AppSettings.self, from: data)
            } catch {
                print("❌ Error cargando configuración: \(error)")
                return AppSettings.default
            }
        }
        
        func resetToDefaults() async {
            UserDefaults.standard.removeObject(forKey: settingsKey)
        }
    
    // Método para debug
    func debugPrintStoredSettings() {
        storageQueue.async {
            if let data = UserDefaults.standard.data(forKey: self.settingsKey) {
                print("📊 Datos de configuración almacenados:")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                }
            } else {
                print("📊 No hay configuración almacenada")
            }
        }
    }
}

// Servicio Mock para Previews
#if DEBUG
class MockSettingsService: SettingsServiceProtocol {
    private var settings = AppSettings.default
    
    func saveSettings(_ settings: AppSettings) async throws {
        self.settings = settings
        print("✅ Configuración mock guardada")
    }
    
    func loadSettings() async throws -> AppSettings {
        print("✅ Configuración mock cargada")
        return settings
    }
    
    func resetToDefaults() async {
        settings = AppSettings.default
        print("🔄 Configuración mock restablecida")
    }
}
#endif
