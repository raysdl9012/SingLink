//
//  CameraPreviewView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Views/CameraPreviewView.swift
import SwiftUI
internal import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let previewView = CameraPreviewUIView()
        previewView.setupPreviewLayer(with: cameraManager.captureSession)
        return previewView
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Actualizar orientación si es necesario
        uiView.updateOrientation()
    }
}

class CameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer type for layer.")
        }
        return layer
    }
    
    func setupPreviewLayer(with session: AVCaptureSession) {
        videoPreviewLayer.session = session
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoRotationAngle = 90
    }
    
    func updateOrientation() {
        guard let connection = videoPreviewLayer.connection else { return }
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait:
            connection.videoRotationAngle = 90
        case .portraitUpsideDown:
            connection.videoRotationAngle = 270
        case .landscapeLeft:
            connection.videoRotationAngle = 0
        case .landscapeRight:
            connection.videoRotationAngle = 180
        default:
            connection.videoRotationAngle = 90
        }
    }
}
