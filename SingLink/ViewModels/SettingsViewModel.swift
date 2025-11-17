//
//  SettingsViewModel.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

internal import Combine
import SwiftUI


class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings = AppSettings.default
    @Published var error: String?
    @Published var isLoading = false
    
    private let settingsService: SettingsServiceProtocol
    
    init(settingsService: SettingsServiceProtocol = SettingsService()) {
        self.settingsService = settingsService
        loadSettings()
    }
    
    func loadSettings() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let loadedSettings = try await settingsService.loadSettings()
                await MainActor.run {
                    self.settings = loadedSettings
                    self.isLoading = false
                    print("✅ Configuración cargada en ViewModel")
                }
            } catch {
                await MainActor.run {
                    self.error = "Error cargando configuración: \(error.localizedDescription)"
                    self.isLoading = false
                    self.settings = AppSettings.default // Fallback a valores por defecto
                    print("❌ Error en ViewModel: \(error)")
                }
            }
        }
    }
    
    func saveSettings() {
        isLoading = true
        error = nil
        
        Task {
            do {
                try await settingsService.saveSettings(settings)
                await MainActor.run {
                    self.isLoading = false
                    print("✅ Configuración guardada desde ViewModel")
                }
            } catch {
                await MainActor.run {
                    self.error = "Error guardando configuración: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Error guardando en ViewModel: \(error)")
                }
            }
        }
    }
    
    func resetToDefaults() {
        settings = AppSettings.default
        saveSettings()
    }
    
    // Método para debug
    func debugSettings() {
        if let service = settingsService as? SettingsService {
            service.debugPrintStoredSettings()
        }
    }
}

