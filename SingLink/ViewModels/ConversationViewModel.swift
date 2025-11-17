//
//  ConversationViewModel.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation
internal import Combine

class ConversationViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let conversationService: ConversationServiceProtocol
    
    init(conversationService: ConversationServiceProtocol = ConversationService()) {
        self.conversationService = conversationService
        loadConversations()
    }
    
    func addMessage(_ text: String, isFromUser: Bool, confidence: Float? = nil) {
        if currentConversation == nil {
            startNewConversation()
        }
        
        let message = ConversationMessage(
            text: text,
            isFromUser: isFromUser,
            timestamp: Date(),
            confidence: confidence
        )
        
        currentConversation?.messages.append(message)
        saveCurrentConversation()
    }
    
    func startNewConversation() {
        currentConversation = Conversation(date: Date(), messages: [])
    }
    
    func deleteConversation(_ conversation: Conversation) {
        Task {
            await conversationService.deleteConversation(conversation.id)
            loadConversations()
            
            if currentConversation?.id == conversation.id {
                currentConversation = nil
            }
        }
    }
    
    func deleteAllConversations() {
        Task {
            await conversationService.deleteAllConversations()
            loadConversations()
            currentConversation = nil
        }
    }
    
    private func saveCurrentConversation() {
        guard let conversation = currentConversation,
              !conversation.messages.isEmpty else { return }
        
        Task {
            await conversationService.saveConversation(conversation)
            loadConversations()
        }
    }
    
    private func loadConversations() {
        Task {
            isLoading = true
            defer { isLoading = false }
            let loadedConversations = await conversationService.loadConversations()
            await MainActor.run {
                self.conversations = loadedConversations.sorted { $0.date > $1.date }
            }
        }
    }
}
