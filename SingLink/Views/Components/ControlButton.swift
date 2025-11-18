
//
//  HeaderButton.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

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
    ControlButton(icon: "camera", color: .green) {
        
    }
}
