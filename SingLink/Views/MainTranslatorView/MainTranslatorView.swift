import SwiftUI
internal import AVFoundation
internal import Combine

struct MainTranslatorView: View {
    // MARK: - Services
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var conversationVM = ConversationViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var dataCollectionService = DataCollectionService.shared
    
    @EnvironmentObject private var memoryManager: MemoryManager
    
    // MARK: - Navigation States
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingTutorial = false
    @State private var showingError = false
    @State private var showingStats = false
    @State private var showingInteractiveTutorial = false
    
    // MARK: - Data Collection States
    @State private var isCollectingData = false
    @State private var currentDataLabel = "Hola"
    @State private var collectionTimer: Timer?
    
    // MARK: - RecognitionService
    @StateObject private var recognitionService = RealSignRecognitionService()
    
    // MARK: - Computed Properties
    private var isCameraActive: Bool {
        cameraManager.isSessionRunning && cameraManager.isAuthorized
    }
    
    private func testRealRecognition() {
        let handPoses = cameraManager.getRealHandPoses()
        
        if let prediction = recognitionService.predictSign(from: handPoses) {
            print("🎯 Predicción real: \(prediction.sign) - Confianza: \(prediction.confidence)")
        }
    }
    
    // MARK: - Main Body
    var body: some View {
        NavigationView {
            ZStack {
                CameraBackgroundView(isActive: isCameraActive)
                    .environmentObject(cameraManager)
                
                predictionView
                
                VStack(spacing: 0) {
                    HeaderView(
                        showingHistory: $showingHistory,
                        showingSettings: $showingSettings,
                        showingStats: $showingStats,
                        dataCollectionService: dataCollectionService,
                        currentDataLabel: currentDataLabel,
                        onDataCollectionTapped: toggleDataCollection
                    )
                    
                    Spacer()

                    ControlsView(
                        cameraManager: cameraManager,
                        isCameraActive: isCameraActive,
                        onToggleCamera: toggleCamera,
                        onSwitchCamera: switchCamera,
                        onClearPrediction: clearPrediction,
                        onShowTutorial: { showingTutorial = true }
                    ).padding(.bottom, 10)
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: onViewAppear)
            .onDisappear(perform: onViewDisappear)
            .configureSheets(showingHistory: $showingHistory,
                             showingStats: $showingStats,
                             showingTutorial: $showingTutorial,
                             conversationVM: conversationVM)
            .configureDebugOverlay()
        }
    }
}

// MARK: - Prediction View
private extension MainTranslatorView {
    var predictionView: some View {
        VStack(spacing: 16) {
            if isCollectingData {
                DataCollectionInProgressView(
                    label: currentDataLabel,
                    sampleCount: dataCollectionService.currentSessionSamples.count
                )
            } else if isCameraActive {
                WaitingForSignView()
            } else {
                CameraInactiveView()
            }
        }
        .padding(.horizontal)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCollectingData)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCameraActive)
    }
}

// MARK: - Data Collection Views
private extension MainTranslatorView {
    struct DataCollectionInProgressView: View {
        let label: String
        let sampleCount: Int
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "record.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                
                VStack(spacing: 8) {
                    Text("Grabando: \(label)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Muestras: \(sampleCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Realiza la seña frente a la cámara")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Lifecycle Management
private extension MainTranslatorView {
    func onViewAppear() {
        if cameraManager.isAuthorized {
            cameraManager.startSession()
        }
        setupInstanceObservers()
        applyPerformanceOptimizations()
    }
    
    func onViewDisappear() {
        cleanupInstanceObservers()
        stopDataCollectionTimer()
    }
}

// MARK: - Camera Management
private extension MainTranslatorView {
    func toggleCamera() {
        if isCameraActive {
            cameraManager.stopSession()
            hapticManager.cameraStopped()
        } else {
            if cameraManager.isAuthorized {
                cameraManager.startSession()
                hapticManager.cameraStarted()
            } else {
                cameraManager.cameraError = .permissionDenied
                hapticManager.errorOccurred()
            }
        }
    }
    
    func switchCamera() {
        cameraManager.switchCamera()
        hapticManager.cameraSwitched()
    }
    
    func clearPrediction() {
        hapticManager.buttonPressed()
        cameraManager.stopSession()
    }
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            hapticManager.errorOccurred()
            return
        }
        UIApplication.shared.open(settingsUrl)
        hapticManager.buttonPressed()
    }
}

// MARK: - Data Collection Management
private extension MainTranslatorView {
    func toggleDataCollection() {
        if dataCollectionService.isRecording {
            stopDataCollectionTimer()
            dataCollectionService.stopRecordingSession()
            isCollectingData = false
        } else {
            showDataCollectionAlert()
        }
    }
    
    func showDataCollectionAlert() {
        let alert = UIAlertController(
            title: "Recolectar Datos",
            message: "Ingresa la seña que vas a grabar:",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Ej: Hola, Gracias, Ayuda"
            textField.autocapitalizationType = .sentences
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Comenzar", style: .default) { [weak alert] _ in
            if let textField = alert?.textFields?.first,
               let label = textField.text, !label.isEmpty {
                self.startDataCollectionSession(for: label)
            }
        })
        
        presentAlert(alert)
    }
    
    private func startDataCollectionSession(for label: String) {
        currentDataLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        dataCollectionService.startRecordingSession()
        isCollectingData = true
        startDataCollectionTimer()
    }
    
    private func presentAlert(_ alert: UIAlertController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Data Collection Timer
private extension MainTranslatorView {
    func startDataCollectionTimer() {
        stopDataCollectionTimer()
        
        collectionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task {
                await self.processDataCollection()
            }
        }
    }
    
    func stopDataCollectionTimer() {
        collectionTimer?.invalidate()
        collectionTimer = nil
    }
    
    func processDataCollection() async {
        guard isCollectingData,
              dataCollectionService.isRecording,
              cameraManager.isSessionRunning else { return }
        
        let handPoses = cameraManager.getRealHandPoses()
        
        guard let bestHandPose = handPoses.sorted(by: { $0.confidence > $1.confidence }).first,
              MLPreprocessor.validateHandPose(bestHandPose) else { return }
        
        await MainActor.run {
            dataCollectionService.recordSample(
                handPose: bestHandPose,
                label: currentDataLabel,
                confidence: bestHandPose.confidence
            )
        }
    }
}

// MARK: - Performance & Memory Management
private extension MainTranslatorView {
    func applyPerformanceOptimizations() {
        let optimizationLevel = BatteryOptimizer.shared.optimizationLevel
        cameraManager.applyPerformanceOptimizations(for: optimizationLevel)
    }
    
    func handleThermalStateChange(_ thermalState: ProcessInfo.ThermalState) {
        if thermalState == .serious || thermalState == .critical {
            cameraManager.pauseProcessing()
        }
    }
    
    func handleMemoryCritical() {
        cameraManager.clearFrameBuffer()
        memoryManager.performMemoryCleanup(for: cameraManager)
    }
}

// MARK: - Notification Observers
private extension MainTranslatorView {
    func setupInstanceObservers() {
        setupAppStateObservers()
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GlobalMemoryCleanup"),
            object: nil,
            queue: .main
        ) { _ in
            self.handleGlobalCleanup()
        }
    }
    
    func setupAppStateObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.cameraManager.pauseProcessing()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            if self.cameraManager.isAuthorized {
                self.cameraManager.startSession()
            }
        }
    }
    
    func cleanupInstanceObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleGlobalCleanup() {
        cameraManager.cleanup()
        cameraManager.clearFrameBuffer()
        memoryManager.performMemoryCleanup(for: cameraManager)
    }
}

// MARK: - View Modifiers
private extension View {
    @ViewBuilder
    func configureSheets(showingHistory:Binding<Bool>,
                         showingStats:Binding<Bool>,
                         showingTutorial:Binding<Bool>,
                         conversationVM: ConversationViewModel) -> some View {
        self
            .sheet(isPresented: showingHistory) {
                ConversationHistoryView(viewModel: conversationVM)
            }
            .sheet(isPresented: showingTutorial) {
                TutorialView()
            }
            .sheet(isPresented: showingStats) {
                DatasetStatsView()
            }
    }
    
    
    @ViewBuilder
    func configureDebugOverlay() -> some View {
#if DEBUG
        self.overlay(alignment: .topLeading) {
            PerformanceDebugView()
                .padding(.top, 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
#else
        self
#endif
    }
}

// MARK: - Preview
#Preview {
    MainTranslatorView()
}
