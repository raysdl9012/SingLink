//
//  SheetModifier.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct SheetModifier: ViewModifier {
    // Declaración de los Bindings necesarios
    @Binding var showingHistory: Bool
    @Binding var showingSettings: Bool
    @Binding var showingTutorial: Bool
    @Binding var showingStats: Bool
    @Binding var showingInteractiveTutorial: Bool
    
    // Dependencias para las Vistas
    let conversationVM: ConversationViewModel // Reemplaza por tu tipo real
    
    // La función body(content:) aplica los modificadores a la vista base
    func body(content: Content) -> some View {
        content // 'content' es la vista a la que se aplica el modificador (ej. ContentView)
            .sheet(isPresented: $showingHistory) {
                ConversationHistoryView(viewModel: conversationVM)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingTutorial) {
                TutorialView()
            }
            .sheet(isPresented: $showingStats) {
                DatasetStatsView()
            }
            .sheet(isPresented: $showingInteractiveTutorial) {
                TutorialInteractivoView()
            }
    }
}

extension View {
    func applySheets(
        showingHistory: Binding<Bool>,
        showingSettings: Binding<Bool>,
        showingTutorial: Binding<Bool>,
        showingStats: Binding<Bool>,
        showingInteractiveTutorial: Binding<Bool>,
        conversationVM: ConversationViewModel,
    ) -> some View {
        self.modifier(SheetModifier(
            showingHistory: showingHistory,
            showingSettings: showingSettings,
            showingTutorial: showingTutorial,
            showingStats: showingStats,
            showingInteractiveTutorial: showingInteractiveTutorial,
            conversationVM: conversationVM,
        ))
    }
}
