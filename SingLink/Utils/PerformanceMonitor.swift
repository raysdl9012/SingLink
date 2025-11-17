//
//  PerformanceMonitor.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Utils/PerformanceMonitor.swift
import Foundation
import UIKit
internal import Combine

final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var memoryUsage: String = "0 MB"
    @Published var batteryImpact: BatteryImpactLevel = .low
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var isMonitoring = false
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount = 0
    private var monitoringTask: Task<Void, Never>?
    
    private init() {
        setupThermalMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startFPSCounter()
        startPeriodicMonitoring()
        
        print("📊 Performance monitoring started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        displayLink?.invalidate()
        displayLink = nil
        monitoringTask?.cancel()
        monitoringTask = nil
        
        print("📊 Performance monitoring stopped")
    }
    
    func logMemoryUsage() -> String {
        let usage = getMemoryUsage()
        memoryUsage = usage
        return usage
    }
    
    func logPerformanceSnapshot() {
        let memory = logMemoryUsage()
        let fps = String(format: "%.1f", currentFPS)
        let thermalStateString = thermalState.description
        let batteryImpactString = batteryImpact.description
        
        print("""
        📊 PERFORMANCE SNAPSHOT:
        🖥️  FPS: \(fps)
        💾 Memory: \(memory)
        🔥 Thermal: \(thermalStateString)
        🔋 Battery: \(batteryImpactString)
        """)
    }
    
    // MARK: - Private Methods
    private func startFPSCounter() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func startPeriodicMonitoring() {
        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                await updatePerformanceMetrics()
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
    }
    
    @objc private func updateFPS(_ displayLink: CADisplayLink) {
        let currentTimestamp = displayLink.timestamp
        
        if lastTimestamp == 0 {
            lastTimestamp = currentTimestamp
            return
        }
        
        frameCount += 1
        let elapsed = currentTimestamp - lastTimestamp
        
        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = currentTimestamp
        }
    }
    
    private func updatePerformanceMetrics() async {
        // Update memory usage
        _ = logMemoryUsage()
        
        // Update battery impact assessment
        await updateBatteryImpact()
        
        // Log snapshot every 30 seconds in debug
#if DEBUG
        if Int(Date().timeIntervalSince1970) % 30 == 0 {
            logPerformanceSnapshot()
        }
#endif
    }
    
    private func getMemoryUsage() -> String {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedBytes = taskInfo.phys_footprint
            let usedMB = Double(usedBytes) / 1024 / 1024
            return String(format: "%.1f MB", usedMB)
        }
        
        return "N/A"
    }
    
    private func setupThermalMonitoring() {
        thermalState = ProcessInfo.processInfo.thermalState
        
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.thermalState = ProcessInfo.processInfo.thermalState
            self?.adjustPerformanceForThermalState()
        }
    }
    
    private func adjustPerformanceForThermalState() {
        switch thermalState {
        case .nominal:
            print("✅ Thermal state: Nominal - Full performance")
        case .fair:
            print("⚠️ Thermal state: Fair - Moderate adjustments")
            // Could reduce frame rate or processing intensity
        case .serious:
            print("🚨 Thermal state: Serious - Significant adjustments")
            // Reduce frame rate, disable heavy processing
        case .critical:
            print("🔥 Thermal state: Critical - Maximum reductions")
            // Minimal functionality, preserve device
        @unknown default:
            break
        }
    }
    
    private func updateBatteryImpact() async {
        // Simulate battery impact assessment based on usage patterns
        // In a real app, you might use more sophisticated metrics
        
        let impact: BatteryImpactLevel
        
        if currentFPS < 30 {
            impact = .high
        } else if memoryUsage.contains("500") { // If using more than 500MB
            impact = .medium
        } else {
            impact = .low
        }
        
        batteryImpact = impact
    }
}

// MARK: - Supporting Types
enum BatteryImpactLevel {
    case low, medium, high
    
    var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: UIColor {
        switch self {
        case .low: return .systemGreen
        case .medium: return .systemOrange
        case .high: return .systemRed
        }
    }
}

extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
