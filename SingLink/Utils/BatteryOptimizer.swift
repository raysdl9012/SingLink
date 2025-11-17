//
//  BatteryOptimizer.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation
internal import Combine
import UIKit

final class BatteryOptimizer: ObservableObject {
    static let shared = BatteryOptimizer()
    
    @Published var isLowPowerModeEnabled = false
    @Published var optimizationLevel: OptimizationLevel = .balanced
    
    private let performanceMonitor = PerformanceMonitor.shared
    private var lowPowerModeObserver: NSObjectProtocol?
    
    private init() {
        setupLowPowerModeObservation()
        updateOptimizationLevel()
    }
    
    deinit {
        if let observer = lowPowerModeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    func applyOptimizations() {
        updateOptimizationLevel()
        
        switch optimizationLevel {
        case .maximumPerformance:
            applyMaximumPerformanceSettings()
        case .balanced:
            applyBalancedSettings()
        case .powerSaving:
            applyPowerSavingSettings()
        case .extremeSaving:
            applyExtremeSavingSettings()
        }
    }
    
    func adjustForThermalState(_ thermalState: ProcessInfo.ThermalState) {
        switch thermalState {
        case .serious, .critical:
            optimizationLevel = .powerSaving
            applyOptimizations()
            print("🔋 Applied power saving optimizations for thermal state")
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func setupLowPowerModeObservation() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        lowPowerModeObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
            self?.updateOptimizationLevel()
            self?.applyOptimizations()
            print("🔋 Low power mode changed: \(self?.isLowPowerModeEnabled == true ? "ON" : "OFF")")
        }
    }
    
    private func updateOptimizationLevel() {
        if isLowPowerModeEnabled {
            optimizationLevel = .powerSaving
        } else {
            // Base on battery level and usage patterns
            let batteryLevel = UIDevice.current.batteryLevel
            if batteryLevel > 0 && batteryLevel < 0.2 { // Below 20%
                optimizationLevel = .extremeSaving
            } else {
                optimizationLevel = .balanced
            }
        }
    }
    
    private func applyMaximumPerformanceSettings() {
        print("🔋 Applied maximum performance settings")
        // Highest quality, full frame rate, all features enabled
    }
    
    private func applyBalancedSettings() {
        print("🔋 Applied balanced settings")
        // Good balance between performance and battery
        // Moderate frame rate, standard processing
    }
    
    private func applyPowerSavingSettings() {
        print("🔋 Applied power saving settings")
        // Reduced frame rate, lighter processing
        // Disable non-essential features
    }
    
    private func applyExtremeSavingSettings() {
        print("🔋 Applied extreme saving settings")
        // Minimal functionality
        // Very low frame rate, basic processing only
    }
}

// MARK: - Supporting Types
enum OptimizationLevel {
    case maximumPerformance
    case balanced
    case powerSaving
    case extremeSaving
    
    var description: String {
        switch self {
        case .maximumPerformance: return "Max Performance"
        case .balanced: return "Balanced"
        case .powerSaving: return "Power Saving"
        case .extremeSaving: return "Extreme Saving"
        }
    }
    
    var recommendedFrameRate: Double {
        switch self {
        case .maximumPerformance: return 60.0
        case .balanced: return 30.0
        case .powerSaving: return 24.0
        case .extremeSaving: return 15.0
        }
    }
}
