// Views/MainTranslatorView.swift
import SwiftUI
internal import AVFoundation
internal import Combine

struct MainTranslatorView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var recognitionService = MockSignRecognitionService()
    @StateObject private var conversationVM = ConversationViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var hapticManager = HapticManager.shared
    
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingTutorial = false
    @State private var showingError = false
    
    @State private var currentPrediction: SignPrediction?
    @State private var isProcessing = false
    
    @State private var signalQuality: SignalQuality = .none
    @State private var detectedHandCount: Int = 0
    @State private var lastDetectionTime: Date?
    @State private var showingInteractiveTutorial = false
    
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @EnvironmentObject private var memoryManager: MemoryManager
    
    //
    @StateObject private var dataCollectionService = DataCollectionService.shared
    @State private var isCollectingData = false
    @State private var currentDataLabel = "Hola"
    
    // En MainTranslatorView - agregar esta variable State
    @State private var showingStats = false
    
    private var isCameraActive: Bool {
        cameraManager.isSessionRunning && cameraManager.isAuthorized
    }
    
    private var shouldShowConfidence: Bool {
        settingsVM.settings.showConfidence // ← Usar configuración
    }
    
    private var shouldUseVibration: Bool {
        settingsVM.settings.vibrationFeedback // ← Usar configuración
    }
    
    private var shouldSaveHistory: Bool {
        settingsVM.settings.saveHistory // ← Usar configuración
    }
    
    private func applyPerformanceOptimizations() {
        let optimizationLevel = BatteryOptimizer.shared.optimizationLevel
        cameraManager.applyPerformanceOptimizations(for: optimizationLevel)
    }
    
    private func handleThermalStateChange(_ thermalState: ProcessInfo.ThermalState) {
        switch thermalState {
        case .serious, .critical:
            print("🔥 Thermal state critical - reducing processing")
            cameraManager.pauseProcessing()
            
        default:
            break
        }
    }
    
    private func handleMemoryCritical() {
        print("🚨 Memory critical - performing cleanup")
        
        currentPrediction = nil
        cameraManager.clearFrameBuffer()
        
        // Usar el método específico con la instancia de cameraManager
        memoryManager.performMemoryCleanup(for: cameraManager)
    }
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                CameraBackgroundView(
                    isActive: isCameraActive
                ).environmentObject(cameraManager)
                
                VStack(spacing: 0) {
                    headerView
                    Spacer()
                    if isCameraActive {
                        CalidadSenalView(
                            quality: signalQuality,
                            handCount: detectedHandCount,
                            confidence: currentPrediction?.confidence ?? 0.0
                        )
                        .padding(.top, 8)
                        .transition(.opacity)
                    }
                    predictionView
                    controlsView
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHistory) {
                ConversationHistoryView(viewModel: conversationVM)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(recognitionService: recognitionService)
            }
            .sheet(isPresented: $showingTutorial) {
                TutorialView()
            }
            .sheet(isPresented: $showingStats) {
                DatasetStatsView()
            }
            .alert("Error de Cámara", isPresented: $showingError, presenting: cameraManager.cameraError) { error in
                Button("OK") { cameraManager.cameraError = nil }
                if error == .permissionDenied {
                    Button("Configuración", action: openAppSettings)
                }
            } message: { error in
                VStack {
                    Text(error.localizedDescription)
                    if let recovery = error.recoverySuggestion {
                        Text(recovery).font(.caption)
                    }
                }
            }
            .onAppear {
                if cameraManager.isAuthorized {
                    cameraManager.startSession()
                }
                if settingsVM.settings.simulationMode {
                    recognitionService.startSimulation()
                }
                setupInstanceObservers()
            }
            .onDisappear {
                // NUEVO: Limpiar observadores
                cleanupInstanceObservers()
            }
            .onChange(of: cameraManager.cameraError) { oldValue, newValue in
                showingError = newValue != nil
            }
            .onChange(of: isCameraActive) { oldValue, newValue in
                if newValue {
                    recognitionService.startSimulation()
                } else {
                    recognitionService.stopSimulation()
                    currentPrediction = nil
                }
            }
            .onChange(of: settingsVM.settings.simulationMode) { oldValue, newValue in
                if newValue && isCameraActive {
                    recognitionService.startSimulation()
                } else {
                    recognitionService.stopSimulation()
                }
            }
            .onChange(of: settingsVM.settings.vibrationFeedback) { oldValue, newValue in
                if newValue {
                    hapticManager.enable()
                } else {
                    hapticManager.disable()
                }
            }
            .onReceive(recognitionService.objectWillChange) { _ in
                if isCameraActive && !isProcessing {
                    processSimulatedPrediction()
                }
            }
            .onChange(of: currentPrediction) { oldValue, newValue in
                if let prediction = newValue, isCollectingData {
                    // Automatically collect data when we have a prediction and are in collection mode
                    collectDataForPrediction(prediction)
                }
            }
            .sheet(isPresented: $showingInteractiveTutorial) {
                TutorialInteractivoView()
            }
            // NUEVO: Debug view solo en desarrollo
#if DEBUG
            .overlay(alignment: .topLeading) {
                PerformanceDebugView()
                    .padding()
            }
#endif
        }
    }
    
    private func quickDataCheck() {
        let stats = dataCollectionService.getDatasetStats()
        print("🔍 QUICK DATA CHECK:")
        print(stats.description)
        
        // Ver los últimos 3 samples
        let recentSamples = dataCollectionService.currentSessionSamples.suffix(3)
        print("📝 Recent samples:")
        for sample in recentSamples {
            print("   • Label: '\(sample.label)', Points: \(sample.handPose.points.count), Confidence: \(sample.confidence)")
        }
    }
    
    // NUEVO: Método para recolectar datos
    private func collectDataForPrediction(_ prediction: SignPrediction) {
        guard let handPoses = getCurrentHandPoses(),
              !handPoses.isEmpty else { return }
        
        // Use the hand pose with highest confidence
        if let bestHandPose = handPoses.sorted(by: { $0.confidence > $1.confidence }).first {
            dataCollectionService.recordSample(
                handPose: bestHandPose,
                label: currentDataLabel,
                confidence: prediction.confidence
            )
        }
    }
    
    private func getCurrentHandPoses() -> [HandPose]? {
        // Este método debería obtener las hand poses actuales de la cámara
        // Por ahora, usaremos las simuladas
        return cameraManager.getSimulatedHandPoses()
    }
    
    
    // NUEVO: Configurar observadores para esta instancia específica
    private func setupInstanceObservers() {
        // Observador para limpieza global de memoria
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GlobalMemoryCleanup"),
            object: nil,
            queue: .main
        ) { _ in
            self.handleGlobalCleanup()
        }
        
        // Observador para cambios de fase de la app
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) {  _ in
            self.cameraManager.pauseProcessing()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            if self.cameraManager.isAuthorized == true {
                self.cameraManager.startSession()
            }
        }
    }
    
    // NUEVO: Limpiar observadores
    private func cleanupInstanceObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("GlobalMemoryCleanup"),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // NUEVO: Manejar limpieza global
    private func handleGlobalCleanup() {
        print("🧹 MainTranslatorView: Handling global cleanup")
        
        // Limpiar recursos de esta instancia
        currentPrediction = nil
        cameraManager.cleanup()
        cameraManager.clearFrameBuffer()
        
        // Realizar limpieza específica con el memoryManager
        memoryManager.performMemoryCleanup(for: cameraManager)
    }
    
    private var headerView: some View {
        HStack {
            HeaderButton(icon: "clock.arrow.circlepath") {
                showingHistory = true
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("SignLink")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Indicador de data collection
                if dataCollectionService.isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text("Grabando: \(currentDataLabel)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Botón para data collection
            HeaderButton(icon: dataCollectionService.isRecording ? "record.circle.fill" : "record.circle") {
                toggleDataCollection()
            }
            .foregroundColor(dataCollectionService.isRecording ? .red : .white)
            
            // NUEVO: Botón de estadísticas
            HeaderButton(icon: "chart.bar.fill") {
                showingStats = true
            }
            
            HeaderButton(icon: "gearshape") {
                showingSettings = true
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // En MainTranslatorView.swift - mejorar el debug
    private func toggleDataCollection() {
        if dataCollectionService.isRecording {
            // ✅ DEBUG MEJORADO: Ver estado antes de parar
            print("🔍 BEFORE STOPPING:")
            print("   - Current session samples: \(dataCollectionService.currentSessionSamples.count)")
            print("   - Total samples: \(dataCollectionService.totalSamplesCollected)")
            print("   - Is recording: \(dataCollectionService.isRecording)")
            
            dataCollectionService.stopRecordingSession()
            isCollectingData = false
            
            // ✅ DEBUG MEJORADO: Ver estado después de parar
            let stats = dataCollectionService.getDatasetStats()
            print("🔍 AFTER STOPPING:")
            print("   - Current session samples: \(dataCollectionService.currentSessionSamples.count)")
            print("   - Total samples: \(dataCollectionService.totalSamplesCollected)")
            print("   - Stats: \(stats.description)")
            
        } else {
            showDataCollectionAlert()
        }
    }
    
    private func showDataCollectionAlert() {
        let alert = UIAlertController(
            title: "Recolectar Datos",
            message: "Ingresa la seña que vas a grabar:",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Ej: Hola, Gracias, Ayuda"
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Comenzar", style: .default) { [weak alert] _ in
            if let textField = alert?.textFields?.first,
               let label = textField.text, !label.isEmpty {
                self.currentDataLabel = label
                self.dataCollectionService.startRecordingSession()
                self.isCollectingData = true
            }
        })
        
        // Presentar el alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func processSimulatedPrediction() {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        Task {
            // Obtener hand poses de la cámara
            let handPoses = cameraManager.getEnhancedHandPoses()
            detectedHandCount = handPoses.count
            
            // ✅ NUEVO: Recolectar datos automáticamente si estamos grabando
            if isCollectingData && !handPoses.isEmpty {
                await collectDataFromHandPoses(handPoses)
            }
            
            // Actualizar calidad de señal
            let avgConfidence = handPoses.map { $0.confidence }.reduce(0, +) / Float(max(handPoses.count, 1))
            signalQuality = SignalQuality.from(handCount: handPoses.count, confidence: avgConfidence)
            
            if !handPoses.isEmpty {
                let prediction = await recognitionService.predictSign(from: handPoses)
                lastDetectionTime = Date()
                
                await MainActor.run {
                    if let prediction = prediction {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentPrediction = prediction
                        }
                        
                        hapticManager.signDetected(confidence: prediction.confidence)
                        
                        if settingsVM.settings.saveHistory {
                            conversationVM.addMessage(
                                prediction.sign,
                                isFromUser: false,
                                confidence: settingsVM.settings.showConfidence ? prediction.confidence : nil
                            )
                        }
                    }
                    isProcessing = false
                }
            } else {
                await MainActor.run {
                    signalQuality = .none
                    isProcessing = false
                }
            }
        }
    }
    
    private func collectDataFromHandPoses(_ handPoses: [HandPose]) async {
        guard isCollectingData, !handPoses.isEmpty else { return }
        
        if let bestHandPose = handPoses.sorted(by: { $0.confidence > $1.confidence }).first {
            if MLPreprocessor.validateHandPose(bestHandPose) {
                await MainActor.run {
                    // ✅ DEBUG DETALLADO
                    print("📸 Attempting to capture sample:")
                    print("   - Label: \(currentDataLabel)")
                    print("   - Hand pose points: \(bestHandPose.points.count)")
                    print("   - Confidence: \(bestHandPose.confidence)")
                    print("   - Is recording: \(dataCollectionService.isRecording)")
                    
                    dataCollectionService.recordSample(
                        handPose: bestHandPose,
                        label: currentDataLabel,
                        confidence: bestHandPose.confidence
                    )
                    
                    print("   ✅ Sample recorded! Session count: \(dataCollectionService.currentSessionSamples.count)")
                }
            } else {
                print("❌ Hand pose validation failed")
            }
        }
    }
    
    private var predictionView: some View {
        VStack(spacing: 16) {
            if let prediction = currentPrediction {
                PredictionCard(
                    prediction: prediction,
                    showConfidence: shouldShowConfidence // ← Pasar configuración
                )
                .transition(.scale.combined(with: .opacity))
            } else if isCameraActive {
                if isProcessing {
                    ProcessingView()
                } else {
                    WaitingForSignView()
                }
            } else {
                CameraInactiveView()
            }
        }
        .padding(.horizontal)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPrediction)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCameraActive)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isProcessing)
    }
    
    private var controlsView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ControlButton(
                    icon: isCameraActive ? "pause.circle.fill" : "play.circle.fill",
                    color: isCameraActive ? .red : .green,
                    action: toggleCamera
                )
                
                if isCameraActive {
                    ControlButton(
                        icon: "arrow.triangle.2.circlepath.camera.fill",
                        color: .blue,
                        action: switchCamera
                    )
                    
                    ControlButton(
                        icon: "xmark.circle.fill",
                        color: .orange,
                        action: clearPrediction
                    )
                    
                    ControlButton(
                        icon: "questionmark.circle.fill",
                        color: .purple,
                        action: { showingTutorial = true }
                    )
                }
            }
            
            StatusView(cameraManager: cameraManager)
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
    }
    
    private func toggleCamera() {
        if isCameraActive {
            cameraManager.stopSession()
            hapticManager.cameraStopped() // ← NUEVO
            clearPrediction()
        } else {
            if cameraManager.isAuthorized {
                cameraManager.startSession()
                hapticManager.cameraStarted() // ← NUEVO
            } else {
                cameraManager.cameraError = .permissionDenied
                hapticManager.errorOccurred() // ← NUEVO
            }
        }
    }
    
    private func switchCamera() {
        cameraManager.switchCamera()
        hapticManager.cameraSwitched() // ← NUEVO
    }
    
    private func clearPrediction() {
        withAnimation {
            currentPrediction = nil
        }
        hapticManager.buttonPressed() // ← NUEVO
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            hapticManager.errorOccurred() // ← NUEVO
            return
        }
        UIApplication.shared.open(settingsUrl)
        hapticManager.buttonPressed() // ← NUEVO
    }
}

struct WaitingForSignView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            VStack(spacing: 8) {
                Text("Esperando señas...")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Realiza señas frente a la cámara")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            isAnimating = true
        }
    }
}

struct ProcessingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            VStack(spacing: 8) {
                Text("Procesando señas...")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Analizando gestos detectados")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct CameraInactiveView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 8) {
                Text("Cámara Inactiva")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Presiona el botón de reproducir para comenzar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StatusView: View {
    let cameraManager: CameraManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                StatusIndicator(
                    title: "Cámara",
                    isActive: cameraManager.isSessionRunning,
                    authorized: cameraManager.isAuthorized
                )
                
                StatusIndicator(
                    title: cameraManager.currentCameraPosition == .front ? "Frontal" : "Trasera",
                    isActive: true,
                    authorized: true
                )
                
                StatusIndicator(
                    title: "Detección",
                    isActive: true,
                    authorized: true
                )
            }
            
            if !cameraManager.isAuthorized {
                Text("Se requiere permiso de cámara")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct StatusIndicator: View {
    let title: String
    let isActive: Bool
    let authorized: Bool
    
    private var color: Color {
        if !authorized {
            return .red
        }
        return isActive ? .green : .orange
    }
    
    private var icon: String {
        if !authorized {
            return "xmark.circle.fill"
        }
        return isActive ? "checkmark.circle.fill" : "pause.circle.fill"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }
}

// Debug View (solo para desarrollo)
struct PerformanceDebugView: View {
    @ObservedObject var monitor = PerformanceMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Debug")
                .font(.headline)
            
            HStack {
                Text("FPS: \(String(format: "%.1f", monitor.currentFPS))")
                Spacer()
                Text(monitor.memoryUsage)
            }
            .font(.caption)
            .monospaced()
            
            HStack {
                Text("Thermal: \(monitor.thermalState.description)")
                Spacer()
                Text("Battery: \(monitor.batteryImpact.description)")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .padding(.top, 50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


#Preview {
    MainTranslatorView()
}
