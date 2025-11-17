//
//  ConversationHistoryView.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import SwiftUI

struct ConversationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ConversationViewModel
    @StateObject private var hapticManager = HapticManager.shared
    
    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive
    @State private var showingDeleteAllAlert = false
    @State private var showingExportSheet = false
    
    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return viewModel.conversations
        } else {
            return viewModel.conversations.filter { conversation in
                conversation.messages.contains { message in
                    message.text.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationListView
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar en conversaciones...")
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !viewModel.conversations.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                showingDeleteAllAlert = true
                            } label: {
                                Label("Eliminar Todo", systemImage: "trash")
                            }
                            
                            Button {
                                showingExportSheet = true
                            } label: {
                                Label("Exportar", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                withAnimation {
                                    editMode = editMode == .active ? .inactive : .active
                                }
                            } label: {
                                Label(
                                    editMode == .active ? "Terminar" : "Editar",
                                    systemImage: editMode == .active ? "checkmark" : "pencil"
                                )
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Eliminar Todo", isPresented: $showingDeleteAllAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    deleteAllConversations()
                }
            } message: {
                Text("¿Estás seguro de que quieres eliminar todo el historial? Esta acción no se puede deshacer.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportHistoryView(conversations: viewModel.conversations)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No hay conversaciones")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Las traducciones aparecerán aquí")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var conversationListView: some View {
        List {
            ForEach(filteredConversations) { conversation in
                ConversationRow(conversation: conversation)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteConversation(conversation)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        
                        Button {
                            shareConversation(conversation)
                        } label: {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            exportConversation(conversation)
                        } label: {
                            Label("Exportar", systemImage: "doc.text")
                        }
                        .tint(.green)
                    }
            }
            .onDelete(perform: deleteConversations)
        }
        .listStyle(PlainListStyle())
        .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !viewModel.conversations.isEmpty {
                        Menu {
                            // ... opciones del menú ...
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .onTapGesture {
                            hapticManager.selection() // ← NUEVO
                        }
                    }
                }
            }
        .overlay {
            if filteredConversations.isEmpty && !searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No se encontraron resultados")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Intenta con otros términos de búsqueda")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Actions
    private func deleteConversation(_ conversation: Conversation) {
            withAnimation {
                viewModel.deleteConversation(conversation)
            }
            hapticManager.deleteAction() // ← NUEVO
        }
        
        private func deleteConversations(at offsets: IndexSet) {
            withAnimation {
                for index in offsets {
                    let conversation = filteredConversations[index]
                    viewModel.deleteConversation(conversation)
                }
            }
            hapticManager.deleteAction() // ← NUEVO
        }
        
        private func deleteAllConversations() {
            withAnimation {
                viewModel.conversations.forEach { conversation in
                    viewModel.deleteConversation(conversation)
                }
            }
            hapticManager.deleteAction() // ← NUEVO
        }
    
    private func shareConversation(_ conversation: Conversation) {
            let text = formatConversationForSharing(conversation)
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
            
            hapticManager.buttonPressed() // ← NUEVO
        }
        
        private func exportConversation(_ conversation: Conversation) {
            let text = formatConversationForSharing(conversation)
            print("📄 Exportar conversación:\n\(text)")
            hapticManager.selection() // ← NUEVO
        }
    
    private func formatConversationForSharing(_ conversation: Conversation) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var text = "Conversación - \(dateFormatter.string(from: conversation.date))\n\n"
        
        for message in conversation.messages {
            let sender = message.isFromUser ? "Tú" : "SignLink"
            let confidence = message.confidence != nil ? " (\(Int(message.confidence! * 100))% confianza)" : ""
            text += "\(sender): \(message.text)\(confidence)\n"
        }
        
        return text
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    private var messagePreview: String {
        conversation.messages.last?.text ?? "Sin mensajes"
    }
    
    private var lastMessageTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: conversation.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conversation.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(lastMessageTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(messagePreview)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            HStack {
                Text("\(conversation.messages.count) mensajes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastMessage = conversation.messages.last {
                    ConfidenceBadge(confidence: lastMessage.confidence)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct ConfidenceBadge: View {
    let confidence: Float?
    
    private var color: Color {
        guard let confidence = confidence else { return .gray }
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private var text: String {
        guard let confidence = confidence else { return "N/A" }
        return "\(Int(confidence * 100))%"
    }
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// Vista de Exportación (Placeholder)
struct ExportHistoryView: View {
    let conversations: [Conversation]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Exportar Historial")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(conversations.count) conversaciones disponibles para exportar")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ExportOptionButton(
                        icon: "text.alignleft",
                        title: "Texto Plano",
                        description: "Exportar como archivo .txt"
                    ) {
                        exportAsText()
                    }
                    
                    ExportOptionButton(
                        icon: "doc.richtext",
                        title: "PDF",
                        description: "Exportar como documento PDF"
                    ) {
                        exportAsPDF()
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Exportar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportAsText() {
        // Implementación futura
        print("📝 Exportar como texto")
        HapticManager.shared.impact(.medium)
    }
    
    private func exportAsPDF() {
        // Implementación futura
        print("📄 Exportar como PDF")
        HapticManager.shared.impact(.medium)
    }
}

struct ExportOptionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ConversationHistoryView(viewModel: ConversationViewModel())
}

