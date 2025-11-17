//
//  HeaderButton.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct HeaderButton: View {
    let icon: String
    let action: () -> Void
    @StateObject private var hapticManager = HapticManager.shared
    
    var body: some View {
        Button(action: {
            hapticManager.buttonPressed()
            action()
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
        }
    }
}

struct ControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @StateObject private var hapticManager = HapticManager.shared
    
    var body: some View {
        Button(action: {
            hapticManager.buttonPressed()
            action()
        }) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    HeaderButton(icon: "camera") {}
}
