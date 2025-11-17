//
//  SingLinkApp.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

@main
struct SignLinkApp: App {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @StateObject private var batteryOptimizer = BatteryOptimizer.shared
    @StateObject private var memoryManager = MemoryManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    // NUEVO: Crear una instancia global para notificaciones
    @State private var globalCameraManager: CameraManager?
    
    init() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        print("🚀 SignLink App Initialized")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            MLTest.testDataCollection()
        }
        
        // Configurar observadores globales
        setupGlobalObservers()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTranslatorView()
                .task {
                    // Start performance monitoring in debug mode
#if DEBUG
                    performanceMonitor.startMonitoring()
#endif
                }
                .onAppear {
                    setupAppLifecycleObservers()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(newPhase)
                }
            // NUEVO: Pasar memoryManager a la vista principal
                .environmentObject(memoryManager)
        }
    }
    
    private func setupGlobalObservers() {
        // Observador para presión de memoria crítica
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MemoryPressureCritical"),
            object: nil,
            queue: .main
        ) { _ in
            self.handleGlobalMemoryPressure()
        }
    }
    
    private func setupAppLifecycleObservers() {
        // Monitor thermal state changes
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            let thermalState = ProcessInfo.processInfo.thermalState
            batteryOptimizer.adjustForThermalState(thermalState)
        }
        
        // Monitor battery level changes
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            batteryOptimizer.applyOptimizations()
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("📱 App became active")
            performanceMonitor.startMonitoring()
            batteryOptimizer.applyOptimizations()
            
        case .inactive:
            print("📱 App became inactive")
            // Pause heavy processing - se manejará en cada instancia específica
            
        case .background:
            print("📱 App moved to background")
            performanceMonitor.stopMonitoring()
            memoryManager.performMemoryCleanup()
            // Stop sessions - se manejará en cada instancia específica
            
        @unknown default:
            break
        }
    }
    
    // NUEVO: Manejar presión de memoria global
    private func handleGlobalMemoryPressure() {
        print("🚨 Global memory pressure detected")
        
        // Limpiar recursos globales
        memoryManager.performMemoryCleanup()
        
        // Notificar a todas las instancias para que se limpien
        NotificationCenter.default.post(
            name: NSNotification.Name("GlobalMemoryCleanup"),
            object: nil
        )
    }
}
