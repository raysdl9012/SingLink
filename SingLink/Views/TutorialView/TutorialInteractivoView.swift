//
//  TutorialInteractivoView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct TutorialInteractivoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var hapticManager = HapticManager.shared
    @State private var currentStep = 0
    @State private var showHandAnimation = false
    @State private var animationProgress: Double = 0.0
    
    let tutorialSteps = [
        TutorialStepInteractive(
            title: "Posición de Manos",
            description: "Mantén las manos dentro del círculo central para mejor detección",
            icon: "hand.raised.fill",
            animation: "position"
        ),
        TutorialStepInteractive(
            title: "Iluminación",
            description: "Asegúrate de tener buena luz y fondo contrastante",
            icon: "lightbulb.fill",
            animation: "lighting"
        ),
        TutorialStepInteractive(
            title: "Movimientos Claros",
            description: "Realiza señas completas y evita movimientos bruscos",
            icon: "hand.draw.fill",
            animation: "movement"
        ),
        TutorialStepInteractive(
            title: "Señas Básicas",
            description: "Comienza con señas simples como 'Hola' y 'Gracias'",
            icon: "waveform.path.ecg",
            animation: "signs"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Aprende Señas")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Cerrar") {
                        hapticManager.buttonPressed()
                        dismiss()
                    }
                }
                .padding()
                
                // Progress Indicator
                ProgressView(value: Double(currentStep + 1), total: Double(tutorialSteps.count))
                    .padding(.horizontal)
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(0..<tutorialSteps.count, id: \.self) { index in
                        TutorialStepInteractiveView(
                            step: tutorialSteps[index],
                            showAnimation: showHandAnimation,
                            animationProgress: animationProgress
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentStep) { oldValue, newValue in
                    hapticManager.selection()
                    resetAnimation()
                }
                
                // Controls
                HStack {
                    if currentStep > 0 {
                        Button("Anterior") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    if currentStep < tutorialSteps.count - 1 {
                        Button("Siguiente") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Comenzar") {
                            hapticManager.notification(.success)
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
            }
            .onAppear {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        showHandAnimation = true
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationProgress = 1.0
        }
    }
    
    private func resetAnimation() {
        showHandAnimation = false
        animationProgress = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startAnimation()
        }
    }
}

struct TutorialStepInteractive: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let animation: String
}

struct TutorialStepInteractiveView: View {
    let step: TutorialStepInteractive
    let showAnimation: Bool
    let animationProgress: Double
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: step.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .scaleEffect(showAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showAnimation)
            }
            
            // Hand Animation based on step
            if step.animation == "position" {
                HandPositionAnimation(progress: animationProgress)
            } else if step.animation == "movement" {
                HandMovementAnimation(progress: animationProgress)
            }
            
            // Text Content
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct HandPositionAnimation: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // Target Circle
            Circle()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: 200, height: 200)
            
            // Animated Hand
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 30))
                .foregroundColor(.green)
                .offset(
                    x: cos(progress * .pi * 2) * 80,
                    y: sin(progress * .pi * 2) * 80
                )
        }
    }
}

struct HandMovementAnimation: View {
    let progress: Double
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .opacity(sin(progress * .pi * 2 + Double(index) * 0.5) * 0.5 + 0.5)
            }
        }
    }
}

// Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    TutorialInteractivoView()
}
