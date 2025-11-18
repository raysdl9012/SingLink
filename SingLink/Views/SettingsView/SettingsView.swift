//
//  SettingsView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

// Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var hapticManager = HapticManager.shared
    
    @State private var showingResetAlert = false
    @State private var showingClearHistoryAlert = false
    @State private var showingErrorAlert = false
    
    let languages = ["LSE", "ASL", "LSM"]
    
    private var saveToogles: some View {
        Section {
            Toggle("Guardar Historial", isOn: $settingsVM.settings.saveHistory)
                .onChange(of: settingsVM.settings.saveHistory) { oldValue, newValue in
                    hapticManager.toggleChanged()
                }
            
            Toggle("Mostrar Confianza", isOn: $settingsVM.settings.showConfidence)
                .onChange(of: settingsVM.settings.showConfidence) { oldValue, newValue in
                    hapticManager.toggleChanged()
                }
            
            Toggle("Vibración", isOn: $settingsVM.settings.vibrationFeedback)
                .onChange(of: settingsVM.settings.vibrationFeedback) { oldValue, newValue in
                    hapticManager.toggleChanged()
                    // Sincronizar con HapticManager
                    if newValue {
                        hapticManager.enable()
                    } else {
                        hapticManager.disable()
                    }
                }
        } header: {
            Text("General")
        }
    }
    
    private var saveLanguaje: some View {
        Section {
            Picker("Lenguaje de Señas", selection: $settingsVM.settings.selectedLanguage) {
                ForEach(languages, id: \.self) { language in
                    Text(language).tag(language)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: settingsVM.settings.selectedLanguage) { oldValue, newValue in
                hapticManager.selection()
            }
        } header: {
            Text("Idioma")
        }
    }
        
    private var cameraSection: some View {
        Section {
            HStack {
                Text("Permiso de Cámara")
                Spacer()
                StatusIndicator(title: "Active",
                                isActive: false,
                                authorized: cameraManager.isAuthorized)
            }
            
            if !cameraManager.isAuthorized {
                Button("Solicitar Permiso") {
                    Task {
                        _ = await cameraManager.requestPermission()
                    }
                    hapticManager.buttonPressed()
                }
                .foregroundColor(.blue)
            }
            
            Button("Cambiar Cámara") {
                cameraManager.switchCamera()
                hapticManager.cameraSwitched()
            }
            .disabled(!cameraManager.isAuthorized)
        } header: {
            Text("Cámara")
        }
    }
    
    private var maintenanceSection: some View {
        Section {
            Button("Limpiar Historial", role: .destructive) {
                hapticManager.buttonPressed()
                showingClearHistoryAlert = true
            }
            
            Button("Restablecer Configuración", role: .destructive) {
                hapticManager.buttonPressed()
                showingResetAlert = true
            }
        } header: {
            Text("Mantenimiento")
        }
    }
    
    private var infoSection: some View {
        Section {
            NavigationLink("Tutorial de Uso") {
                TutorialView()
            }
            .onTapGesture {
                hapticManager.selection()
            }
            
            NavigationLink("Acerca de") {
                AboutView()
            }
            .onTapGesture {
                hapticManager.selection()
            }
            
            // ... resto de elementos ...
        } header: {
            Text("Información")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    // Sección General - Agregar onChange para toggles
                    saveToogles
                    
                    // Sección Idioma
                    saveLanguaje
                    
                    // Sección Cámara - Agregar feedback a botones
                    cameraSection
                    
                    // Sección Mantenimiento - Agregar feedback a botones
                    maintenanceSection
                    
                    // Sección Información
                    infoSection
                    
                }
                .disabled(settingsVM.isLoading)
                
                // Loading Overlay
                if settingsVM.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Guardando configuración...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        settingsVM.saveSettings()
                        dismiss()
                    }
                    .disabled(settingsVM.isLoading)
                }
            }
            
            .alert("Limpiar Historial", isPresented: $showingClearHistoryAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Limpiar", role: .destructive) {
                    clearAllHistory()
                }
            } message: {
                Text("¿Estás seguro de que quieres eliminar todo el historial de conversaciones? Esta acción no se puede deshacer.")
            }
            .alert("Restablecer Configuración", isPresented: $showingResetAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Restablecer", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("¿Estás seguro de que quieres restablecer toda la configuración a los valores predeterminados?")
            }
            .onAppear {
                settingsVM.loadSettings()
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(settingsVM.error ?? "Error desconocido")
            }
            .onChange(of: settingsVM.error) { oldValue, newValue in
                showingErrorAlert = newValue != nil
            }
            .onAppear {
                settingsVM.loadSettings()
            }
        }
    }
    
    // MARK: - Actions
    private func clearAllHistory() {
        Task {
            let conversationVM = ConversationViewModel()
            conversationVM.deleteAllConversations()
            HapticManager.shared.notification(.warning)
        }
    }
    
    private func resetToDefaults() {
        settingsVM.resetToDefaults()
        HapticManager.shared.notification(.success)
    }
}

// Componente de Indicador de Estado
struct StatusIndicatorSettings: View {
    let isAuthorized: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isAuthorized ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(isAuthorized ? "Autorizado" : "Denegado")
                .font(.caption)
                .foregroundColor(isAuthorized ? .green : .red)
        }
    }
}

#Preview {
    SettingsView()
}


