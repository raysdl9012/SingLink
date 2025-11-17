//
//  MemoryManager.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation
internal import Combine
import UIKit


final class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published var memoryWarningCount = 0
    @Published var lastMemoryWarningDate: Date?
    @Published var isMemoryCritical = false
    
    private var memoryWarningObserver: NSObjectProtocol?
    private var cleanupTimer: Timer?
    
    private init() {
        setupMemoryWarningObservation()
        startPeriodicCleanup()
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func performMemoryCleanup() {
        print("🧹 Performing memory cleanup...")
        
        // Clear various caches and temporary data
        clearImageCaches()
        clearTemporaryData()
        requestViewControllersCleanup()
        
        // Force garbage collection (through autorelease pool)
        autoreleasepool {
            // Any Objective-C objects will be released here
        }
        
        print("🧹 Memory cleanup completed")
    }
    
    // NUEVO MÉTODO: Cleanup con referencia a CameraManager específica
    func performMemoryCleanup(for cameraManager: CameraManager) {
        print("🧹 Performing memory cleanup with camera manager...")
        
        // Clear camera-specific resources
        cameraManager.cleanup()
        cameraManager.clearFrameBuffer()
        
        // Clear general resources
        clearImageCaches()
        clearTemporaryData()
        
        autoreleasepool {
            // Cleanup Objective-C objects
        }
        
        print("🧹 Memory cleanup with camera manager completed")
    }
    
    func monitorMemoryUsage() -> String {
        return PerformanceMonitor.shared.logMemoryUsage()
    }
    
    func isMemoryUsageCritical() -> Bool {
        let usage = monitorMemoryUsage()
        // Simple heuristic: if using more than 500MB, consider it critical
        if let mbValue = Double(usage.replacingOccurrences(of: " MB", with: "")) {
            return mbValue > 500.0
        }
        return false
    }
    
    // MARK: - Private Methods
    private func setupMemoryWarningObservation() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        memoryWarningCount += 1
        lastMemoryWarningDate = Date()
        isMemoryCritical = true
        
        print("🚨 Memory warning received! Count: \(memoryWarningCount)")
        
        // Notify other components (without specific CameraManager reference)
        notifyMemoryPressure()
    }
    
    private func performAggressiveCleanup() {
        print("🧹 Performing aggressive memory cleanup")
        
        // Clear all possible caches
        clearImageCaches()
        clearTemporaryData()
        clearAllNonEssentialData()
        
        // CORRECCIÓN: No referenciar CameraManager.shared
        // Las instancias específicas se limpiarán cuando reciban la notificación
        
        // Reduce cache sizes
        URLCache.shared.removeAllCachedResponses()
        
        print("🧹 Aggressive memory cleanup completed")
    }
    
    private func clearImageCaches() {
        // Clear any image caches
        UIImageView.clearAllCachedImages()
    }
    
    private func clearTemporaryData() {
        // Clear temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for file in tempFiles {
                try? FileManager.default.removeItem(at: file)
            }
        } catch {
            print("❌ Error clearing temp directory: \(error)")
        }
    }
    
    private func clearAllNonEssentialData() {
        // Clear any non-essential data that can be recreated
        // This would be app-specific
    }
    
    private func requestViewControllersCleanup() {
        // Notify all view controllers to cleanup
        NotificationCenter.default.post(name: NSNotification.Name("MemoryCleanupRequest"), object: nil)
    }
    
    private func notifyMemoryPressure() {
        // Notify performance monitor
        PerformanceMonitor.shared.logPerformanceSnapshot()
        
        // Notify battery optimizer to apply extreme savings
        BatteryOptimizer.shared.adjustForThermalState(.critical)
        
        // Notify about memory pressure
        NotificationCenter.default.post(
            name: NSNotification.Name("MemoryPressureCritical"),
            object: nil
        )
    }
    
    private func startPeriodicCleanup() {
        // Cleanup every 5 minutes to prevent memory buildup
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performMemoryCleanup()
        }
    }
}

// Extension to clear UIImageView caches (if any)
extension UIImageView {
    static func clearAllCachedImages() {
        // This is a placeholder - in a real app you might have custom image caching
    }
}
