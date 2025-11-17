//
//  CaneraNabager.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

internal import AVFoundation
internal import Combine
import UIKit
import Vision

final class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var cameraError: CameraError?
    @Published var currentFrame: CGImage?
    @Published var currentCameraPosition: AVCaptureDevice.Position = .front
    
    // MARK: - Private Properties
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.signlink.camera.session")
    private var context = CIContext()
    private var currentInput: AVCaptureDeviceInput?
    
    // MARK: - Public Properties
    var isAuthorized: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCaptureSession()
        setupAutoRecovery()
    }
    
    deinit {
        stopSession()
        NotificationCenter.default.removeObserver(self)
    }
    
    func getCamerasesids() -> AVCaptureSession {
        captureSession
    }
    
    // MARK: - Public Methods
    func startSession() {
        guard !captureSession.isRunning else { return }
        
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
                self?.cameraError = nil
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let currentPosition = self.currentCameraPosition
            let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
            
            guard let newCamera = self.getCameraDevice(for: newPosition) else {
                DispatchQueue.main.async {
                    self.cameraError = .deviceNotFound
                }
                return
            }
            
            do {
                self.captureSession.beginConfiguration()
                
                // Remove current input
                if let currentInput = self.currentInput {
                    self.captureSession.removeInput(currentInput)
                }
                
                // Add new input
                let newVideoInput = try AVCaptureDeviceInput(device: newCamera)
                guard self.captureSession.canAddInput(newVideoInput) else {
                    throw CameraError.cannotAddInput
                }
                self.captureSession.addInput(newVideoInput)
                self.currentInput = newVideoInput
                
                // Configure connection
                if let connection = self.videoOutput.connection(with: .video) {
                    connection.videoRotationAngle = 90
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = newPosition == .front
                    }
                }
                
                self.captureSession.commitConfiguration()
                
                DispatchQueue.main.async {
                    self.currentCameraPosition = newPosition
                }
                
            } catch {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    self.cameraError = .configurationError(error)
                }
            }
        }
    }
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                continuation.resume(returning: true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            case .denied, .restricted:
                continuation.resume(returning: false)
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    private func configureCaptureSession() {
        Task {
            let authorized = await requestPermission()
            
            if authorized {
                await setupCameraDevice()
            } else {
                await MainActor.run {
                    self.cameraError = .permissionDenied
                }
            }
        }
    }
    
    @MainActor
    private func setupCameraDevice() async {
        do {
            try await setupCaptureSessionWithCamera()
        } catch {
            self.cameraError = .configurationError(error)
        }
    }
    
    private func setupCaptureSessionWithCamera() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    self.captureSession.beginConfiguration()
                    
                    // Configure session preset
                    self.captureSession.sessionPreset = .hd1280x720
                    
                    // Get front camera by default
                    guard let camera = self.getCameraDevice(for: .front) else {
                        throw CameraError.deviceNotFound
                    }
                    
                    // Configure input
                    let videoInput = try AVCaptureDeviceInput(device: camera)
                    guard self.captureSession.canAddInput(videoInput) else {
                        throw CameraError.cannotAddInput
                    }
                    self.captureSession.addInput(videoInput)
                    self.currentInput = videoInput
                    
                    // Configure output
                    self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    self.videoOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                    ]
                    
                    guard self.captureSession.canAddOutput(self.videoOutput) else {
                        throw CameraError.cannotAddOutput
                    }
                    self.captureSession.addOutput(self.videoOutput)
                    
                    // Configure connection
                    if let connection = self.videoOutput.connection(with: .video) {
                        connection.videoRotationAngle = 90
                        if connection.isVideoMirroringSupported {
                            connection.isVideoMirrored = true
                        }
                    }
                    
                    self.captureSession.commitConfiguration()
                    
                    DispatchQueue.main.async {
                        self.currentCameraPosition = .front
                    }
                    
                    continuation.resume()
                    
                } catch {
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
    
    // MARK: - Performance Optimizations (CORREGIDO)
    private func setupPerformanceOptimizations() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let currentInput = self.currentInput else { return }
            
            let device = currentInput.device
            
            do {
                try device.lockForConfiguration()
                
                // Set optimal frame rate if supported
                if device.activeFormat.videoSupportedFrameRateRanges.count > 0 {
                    let range = device.activeFormat.videoSupportedFrameRateRanges[0]
                    let targetFrameRate = min(30.0, range.maxFrameRate)
                    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
                    device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
                }
                
                device.unlockForConfiguration()
            } catch {
                print("❌ Error configuring camera device: \(error)")
            }
        }
    }
    
    // MARK: - Auto-Recovery (CORREGIDO)
    private func setupAutoRecovery() {
        NotificationCenter.default.addObserver(
            forName: AVCaptureSession.wasInterruptedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("⚠️ Sesión de cámara interrumpida")
            self?.handleSessionInterruption()
        }
        
        NotificationCenter.default.addObserver(
            forName: AVCaptureSession.interruptionEndedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("✅ Interrupción de cámara finalizada")
            self?.handleSessionRecovery()
        }
    }
    
    private func handleSessionInterruption() {
        isSessionRunning = false
    }
    
    private func handleSessionRecovery() {
        // CORRECCIÓN: Usar self correctamente
        if self.isAuthorized {
            self.startSession()
        }
    }
    
    // MARK: - Memory Management
    func cleanup() {
        stopSession()
        
        // Remove all inputs and outputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        
        // Clear current frame
        currentFrame = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        Task { @MainActor in
            let transformedImage = self.currentCameraPosition == .front ?
            self.applyMirrorTransform(to: ciImage) : ciImage
            
            if let cgImage = self.context.createCGImage(transformedImage, from: transformedImage.extent) {
                self.currentFrame = cgImage
            }
        }
    }
    
    private func applyMirrorTransform(to image: CIImage) -> CIImage {
        return image.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            .transformed(by: CGAffineTransform(translationX: image.extent.width, y: 0))
    }
}

// MARK: - Hand Pose Simulation Extension
extension CameraManager {
    
    // Función básica de simulación
    func getSimulatedHandPoses() -> [HandPose] {
        guard isSessionRunning else { return [] }
        
        let handCount = Int.random(in: 0...2)
        var handPoses: [HandPose] = []
        
        for _ in 0..<handCount {
            let confidence = Float.random(in: 0.6...0.95)
            let simulatedPoints = simulateHandPoints()
            
            let handPose = HandPose(
                points: simulatedPoints,
                confidence: confidence,
                timestamp: Date()
            )
            handPoses.append(handPose)
        }
        
        return handPoses
    }
    
    // Función mejorada de simulación
    func getEnhancedHandPoses() -> [HandPose] {
        guard isSessionRunning else { return [] }
        
        // Simulate realistic detection patterns
        let detectionProbability: Float = currentCameraPosition == .front ? 0.8 : 0.6
        let shouldDetect = Float.random(in: 0...1) < detectionProbability
        
        guard shouldDetect else { return [] }
        
        let handCount = weightedHandCount()
        var handPoses: [HandPose] = []
        
        for i in 0..<handCount {
            let (confidence, points) = generateRealisticHandData(handIndex: i)
            
            let handPose = HandPose(
                points: points,
                confidence: confidence,
                timestamp: Date()
            )
            handPoses.append(handPose)
        }
        
        return handPoses
    }
    
    private func weightedHandCount() -> Int {
        let random = Float.random(in: 0...1)
        switch random {
        case 0..<0.6: return 1
        case 0.6..<0.9: return 2
        default: return 0
        }
    }
    
    private func generateRealisticHandData(handIndex: Int) -> (Float, [SimulatedPoint]) {
        let baseConfidence = Float.random(in: 0.4...0.95)
        let points = generateRealisticHandPoints(handIndex: handIndex)
        
        let avgPointConfidence = points.map { $0.confidence }.reduce(0, +) / Float(points.count)
        let finalConfidence = (baseConfidence + avgPointConfidence) / 2
        
        return (finalConfidence, points)
    }
    
    private func generateRealisticHandPoints(handIndex: Int) -> [SimulatedPoint] {
        let jointNames = [
            "wrist", "thumbCMC", "thumbMP", "thumbIP", "thumbTip",
            "indexMCP", "indexPIP", "indexDIP", "indexTip",
            "middleMCP", "middlePIP", "middleDIP", "middleTip",
            "ringMCP", "ringPIP", "ringDIP", "ringTip",
            "littleMCP", "littlePIP", "littleDIP", "littleTip"
        ]
        
        var points: [SimulatedPoint] = []
        
        let baseX: Double = handIndex == 0 ? 0.3 : 0.7
        let baseY: Double = 0.5
        
        for jointName in jointNames {
            let x = baseX + Double.random(in: -0.1...0.1)
            let y = baseY + Double.random(in: -0.1...0.1)
            let confidence = Float.random(in: 0.7...0.98)
            
            let point = SimulatedPoint(
                x: max(0.1, min(0.9, x)),
                y: max(0.1, min(0.9, y)),
                confidence: confidence,
                jointName: jointName
            )
            points.append(point)
        }
        
        return points
    }
    
    private func simulateHandPoints() -> [SimulatedPoint] {
        let jointNames = [
            "wrist", "thumbCMC", "thumbMP", "thumbIP", "thumbTip",
            "indexMCP", "indexPIP", "indexDIP", "indexTip",
            "middleMCP", "middlePIP", "middleDIP", "middleTip",
            "ringMCP", "ringPIP", "ringDIP", "ringTip",
            "littleMCP", "littlePIP", "littleDIP", "littleTip"
        ]
        
        var points: [SimulatedPoint] = []
        
        for jointName in jointNames {
            let point = SimulatedPoint(
                x: Double.random(in: 0.2...0.8),
                y: Double.random(in: 0.2...0.8),
                confidence: Float.random(in: 0.7...0.95),
                jointName: jointName
            )
            points.append(point)
        }
        
        return points
    }
}

// Managers/CameraManager.swift - Agregar estas extensiones
extension CameraManager {
    
    // MARK: - Advanced Performance Optimizations
    func applyPerformanceOptimizations(for level: OptimizationLevel) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let currentInput = self.currentInput else { return }
            
            let device = currentInput.device
            
            do {
                try device.lockForConfiguration()
                
                // Adjust frame rate based on optimization level
                self.adjustFrameRate(device, for: level)
                
                // Adjust video settings for performance
                self.adjustVideoSettings(device, for: level)
                
                device.unlockForConfiguration()
                
                print("📹 Applied camera optimizations for: \(level.description)")
                
            } catch {
                print("❌ Error applying camera optimizations: \(error)")
            }
        }
    }
    
    private func adjustFrameRate(_ device: AVCaptureDevice, for level: OptimizationLevel) {
        guard device.activeFormat.videoSupportedFrameRateRanges.count > 0 else { return }
        
        let range = device.activeFormat.videoSupportedFrameRateRanges[0]
        let targetFrameRate = min(level.recommendedFrameRate, range.maxFrameRate)
        
        device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
        device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
        
        print("📹 Adjusted frame rate to: \(targetFrameRate) FPS")
    }
    
    private func adjustVideoSettings(_ device: AVCaptureDevice, for level: OptimizationLevel) {
        switch level {
        case .maximumPerformance, .balanced:
            // Higher quality settings
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
        case .powerSaving, .extremeSaving:
            // Lower quality, better battery
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }
        }
    }
    
    // MARK: - Intelligent Suspension
    func pauseProcessing() {
        // Reduce processing when app is in background or not actively used
        videoOutput.setSampleBufferDelegate(nil, queue: sessionQueue)
        print("📹 Camera processing paused")
    }
    
    func resumeProcessing() {
        // Resume normal processing
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        print("📹 Camera processing resumed")
    }
    
    // MARK: - Memory Management Enhancements
    func clearFrameBuffer() {
        // Clear the current frame to free memory
        currentFrame = nil
    }
    
    func optimizeMemoryUsage() {
        sessionQueue.async { [weak self] in
            // Reduce session preset if needed
            if self?.captureSession.sessionPreset == .hd1920x1080 {
                self?.captureSession.sessionPreset = .hd1280x720
                print("📹 Reduced session preset for memory optimization")
            }
            
            // Clear frame buffer
            DispatchQueue.main.async {
                self?.clearFrameBuffer()
            }
        }
    }
}
