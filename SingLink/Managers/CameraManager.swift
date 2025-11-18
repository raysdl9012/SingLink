//
//  CameraManager.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import UIKit
import Vision
internal import AVFoundation
internal import Combine


/**
 Gestor centralizado de la cámara para SignLink.
 
 Maneja la configuración, captura y procesamiento de video en tiempo real,
 proporcionando frames para el reconocimiento de señas y hand pose detection.
 
 - Configura sesiones de captura con AVCaptureSession
 - Proporciona frames procesados como CGImage
 - Maneja cambios entre cámaras frontal/trasera
 - Incluye sistema de recuperación automática ante interrupciones
 */
final class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var cameraError: CameraError?
    @Published var currentFrame: CGImage?
    @Published var currentCameraPosition: AVCaptureDevice.Position = .front
    
    // MARK: - Private Properties
    public let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.signlink.camera.session", qos: .userInitiated)
    private var context = CIContext()
    private var currentInput: AVCaptureDeviceInput?
    
    // MARK: - Vision Properties
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    @Published var currentHandPoses: [HandPose] = []
    
    
    // MARK: - Public Properties
    var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCaptureSession()
        setupAutoRecovery()
        setupVisionRequest()
    }
    
    deinit {
        stopSession()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Public Session Management
extension CameraManager {
    
    /// Inicia la sesión de captura de la cámara
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
    
    /// Detiene la sesión de captura de la cámara
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    /// Cambia entre cámaras frontal y trasera
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let newPosition: AVCaptureDevice.Position = self.currentCameraPosition == .back ? .front : .back
            self.switchToCamera(position: newPosition)
        }
    }
    
    /// Solicita permiso para usar la cámara
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
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
}

// MARK: - Private Session Configuration
private extension CameraManager {
    
    func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    func configureCaptureSession() {
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
    func setupCameraDevice() async {
        do {
            try await setupCaptureSessionWithCamera()
        } catch {
            self.cameraError = .configurationError(error)
        }
    }
    
    func setupCaptureSessionWithCamera() async throws {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    self.captureSession.beginConfiguration()
                    // Configurar preset de sesión
                    self.captureSession.sessionPreset = .hd1280x720
                    
                    // Configurar cámara frontal por defecto
                    try self.setupFrontCamera()
                    
                    // Configurar salida de video
                    try self.setupVideoOutput()
                    
                    // Configurar conexión
                    self.setupVideoConnection()
                    
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
    
    private func setupFrontCamera() throws {
        guard let camera = getCameraDevice(for: .front) else {
            throw CameraError.deviceNotFound
        }
        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard captureSession.canAddInput(videoInput) else {
            throw CameraError.cannotAddInput
        }
        captureSession.addInput(videoInput)
        currentInput = videoInput
    }
    
    private func setupVideoOutput() throws {
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(videoOutput)
    }
    
    private  func setupVideoConnection() {
        guard let connection = videoOutput.connection(with: .video) else { return }
        connection.videoRotationAngle = 90
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
    }
    
    func switchToCamera(position: AVCaptureDevice.Position) {
        guard let newCamera = getCameraDevice(for: position) else {
            DispatchQueue.main.async {
                self.cameraError = .deviceNotFound
            }
            return
        }
        
        do {
            captureSession.beginConfiguration()
            // Remover entrada actual
            if let currentInput = currentInput {
                captureSession.removeInput(currentInput)
            }
            // Agregar nueva entrada
            let newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            guard captureSession.canAddInput(newVideoInput) else {
                throw CameraError.cannotAddInput
            }
            captureSession.addInput(newVideoInput)
            currentInput = newVideoInput
            // Reconfigurar conexión
            setupVideoConnectionForPosition(position)
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.currentCameraPosition = position
            }
            
        } catch {
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.cameraError = .configurationError(error)
            }
        }
    }
    
    private func setupVideoConnectionForPosition(_ position: AVCaptureDevice.Position) {
        guard let connection = videoOutput.connection(with: .video) else { return }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = position == .front
        }
    }
    
    private func getCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
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

        Task {
            await self.processHandPoseDetection(in: pixelBuffer)
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let transformedImage = await self.currentCameraPosition == .front ?
            self.applyMirrorTransform(to: ciImage) : ciImage
            
            if let cgImage = await self.context.createCGImage(transformedImage, from: transformedImage.extent) {
                await MainActor.run {
                    self.currentFrame = cgImage
                }
            }
        }
    }
    
    private func applyMirrorTransform(to image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            .transformed(by: CGAffineTransform(translationX: image.extent.width, y: 0))
    }
    
    @MainActor
    private func processHandPoseDetection(in pixelBuffer: CVPixelBuffer) {
        let requestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )
        
        do {
            try requestHandler.perform([handPoseRequest])
            self.processHandPoseResults()
            
        } catch {
            print("❌ Error en detección de hand poses: \(error)")
        }
    }
    
    @MainActor
    private func processHandPoseResults() {
        guard let observations = handPoseRequest.results else {
            currentHandPoses = []
            print("🔍 Vision: No hands detected")
            return
        }
        
        var detectedHandPoses: [HandPose] = []
        
        for (index, observation) in observations.enumerated() {
            if let handPose = convertVisionObservationToHandPose(observation) {
                detectedHandPoses.append(handPose)
                print("🔍 Vision: Hand \(index + 1) - Confidence: \(handPose.confidence), Points: \(handPose.points.count)")
            }
        }
        
        currentHandPoses = detectedHandPoses
        
        if !detectedHandPoses.isEmpty {
            print("🎯 Vision: Detected \(detectedHandPoses.count) hand(s)")
        }
    }
}

// MARK: - Hand Pose Simulation
extension CameraManager {
    func getRealHandPoses() -> [HandPose] {
        return currentHandPoses
    }
    
    func getEnhancedHandPoses() -> [HandPose] {
        return getRealHandPoses()
    }
}

// MARK: - Performance Optimization
extension CameraManager {
    
    /// Aplica optimizaciones de rendimiento basadas en el nivel especificado
    /// - Parameter level: Nivel de optimización a aplicar
    func applyPerformanceOptimizations(for level: OptimizationLevel) {
        sessionQueue.async { [weak self] in
            guard let self = self, let currentInput = self.currentInput else { return }
            
            let device = currentInput.device
            
            do {
                try device.lockForConfiguration()
                self.adjustFrameRate(device, for: level)
                self.adjustVideoSettings(device, for: level)
                device.unlockForConfiguration()
            } catch {
                // Error silencioso para optimizaciones
            }
        }
    }
    
    private func adjustFrameRate(_ device: AVCaptureDevice, for level: OptimizationLevel) {
        guard let range = device.activeFormat.videoSupportedFrameRateRanges.first else { return }
        
        let targetFrameRate = min(level.recommendedFrameRate, range.maxFrameRate)
        device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
        device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
    }
    
    private func adjustVideoSettings(_ device: AVCaptureDevice, for level: OptimizationLevel) {
        switch level {
        case .maximumPerformance, .balanced:
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
        case .powerSaving, .extremeSaving:
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }
        }
    }
    
    func pauseProcessing() {
        videoOutput.setSampleBufferDelegate(nil, queue: sessionQueue)
    }
    
    func resumeProcessing() {
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    }
}

// MARK: - Memory Management
extension CameraManager {
    
    func cleanup() {
        stopSession()
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        currentFrame = nil
    }
    
    func clearFrameBuffer() {
        currentFrame = nil
    }
    
    func optimizeMemoryUsage() {
        sessionQueue.async { [weak self] in
            if self?.captureSession.sessionPreset == .hd1920x1080 {
                self?.captureSession.sessionPreset = .hd1280x720
            }
            
            DispatchQueue.main.async {
                self?.clearFrameBuffer()
            }
        }
    }
}

// MARK: - Auto-Recovery System
private extension CameraManager {
    
    func setupAutoRecovery() {
        NotificationCenter.default.addObserver(
            forName: AVCaptureSession.wasInterruptedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSessionInterruption()
        }
        
        NotificationCenter.default.addObserver(
            forName: AVCaptureSession.interruptionEndedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSessionRecovery()
        }
    }
    
    func handleSessionInterruption() {
        isSessionRunning = false
    }
    
    func handleSessionRecovery() {
        if isAuthorized {
            startSession()
        }
    }
}

// MARK: VISION

extension CameraManager {
    
    private func setupVisionRequest() {
        handPoseRequest.maximumHandCount = 2 // Máximo 2 manos
        handPoseRequest.revision = VNDetectHumanHandPoseRequestRevision1
    }
    
    private func convertVisionObservationToHandPose(_ observation: VNHumanHandPoseObservation) -> HandPose? {
        do {
            // Obtener todos los puntos de la mano
            let recognizedPoints = try observation.recognizedPoints(.all)
            
            var simulatedPoints: [SimulatedPoint] = []
            var totalConfidence: Float = 0.0
            
            // Mapear puntos de Vision a SimulatedPoint
            for (joint, point) in recognizedPoints {
                guard point.confidence > 0.1 else { continue } // Filtrar puntos con baja confianza
                
                // ✅ CORRECCIÓN: Convertir VNRecognizedPointKey a String
                let jointName = getJointName(from: joint.rawValue)
                
                let simulatedPoint = SimulatedPoint(
                    x: Double(point.location.x),
                    y: Double(1.0 - point.location.y), // Vision usa coordenadas invertidas en Y
                    confidence: point.confidence,
                    jointName: jointName
                )
                
                simulatedPoints.append(simulatedPoint)
                totalConfidence += point.confidence
            }
            
            // Calcular confianza promedio
            let averageConfidence = simulatedPoints.isEmpty ? 0.0 : totalConfidence / Float(simulatedPoints.count)
            
            // Solo retornar si tenemos puntos válidos
            guard !simulatedPoints.isEmpty, averageConfidence > 0.3 else {
                return nil
            }
            
            return HandPose(
                points: simulatedPoints,
                confidence: averageConfidence,
                timestamp: Date()
            )
            
        } catch {
            print("❌ Error convirtiendo observación de Vision: \(error)")
            return nil
        }
    }
    
    // ✅ NUEVO: Método para convertir VNRecognizedPointKey a String
    private func getJointName(from jointKey: VNRecognizedPointKey) -> String {
        // Convertir la key a String y extraer el nombre del joint
        let keyString = "\(jointKey)"
        
        // Extraer el nombre del joint del string completo
        // El formato típico es: "VNRecognizedPointKey(_rawValue: thumbTip)"
        if let range = keyString.range(of: "_rawValue: ") {
            let jointName = String(keyString[range.upperBound...].dropLast())
            return jointName
        }
        
        return keyString
    }
}


