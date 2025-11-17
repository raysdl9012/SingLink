//
//  ConversationService.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

// Services/ConversationService.swift
import Foundation

protocol ConversationServiceProtocol {
    func saveConversation(_ conversation: Conversation) async
    func loadConversations() async -> [Conversation]
    func deleteConversation(_ id: UUID) async
    func deleteAllConversations() async
}

final class ConversationService: ConversationServiceProtocol {
    private let storageKey = "signlink_conversations"
    private let storageQueue = DispatchQueue(
        label: "com.signlink.conversation.storage",
        qos: .userInitiated
    )
    
    // MARK: - Save Conversation
    func saveConversation(_ conversation: Conversation) async {
        await withCheckedContinuation { continuation in
            storageQueue.async {
                var conversations = self.loadConversationsFromDisk()
                
                if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                    conversations[index] = conversation
                } else {
                    conversations.append(conversation)
                }
                
                self.saveConversationsToDisk(conversations)
                continuation.resume()
            }
        }
    }
    
    // MARK: - Load Conversations
    func loadConversations() async -> [Conversation] {
        await withCheckedContinuation { continuation in
            storageQueue.async {
                let conversations = self.loadConversationsFromDisk()
                continuation.resume(returning: conversations)
            }
        }
    }
    
    // MARK: - Delete Conversation
    func deleteConversation(_ id: UUID) async {
        await withCheckedContinuation { continuation in
            storageQueue.async {
                var conversations = self.loadConversationsFromDisk()
                conversations.removeAll { $0.id == id }
                self.saveConversationsToDisk(conversations)
                continuation.resume()
            }
        }
    }
    
    // MARK: - Delete All Conversations
    func deleteAllConversations() async {
        await withCheckedContinuation { continuation in
            storageQueue.async {
                self.saveConversationsToDisk([])
                continuation.resume()
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadConversationsFromDisk() -> [Conversation] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Conversation].self, from: data)
        } catch {
            print("❌ Error loading conversations: \(error)")
            
            // CORRECCIÓN: Intentar recuperar con estrategia flexible
            return self.loadConversationsWithFallback(data: data)
        }
    }
    
    private func loadConversationsWithFallback(data: Data) -> [Conversation] {
        let decoder = JSONDecoder()
        
        // Intentar diferentes estrategias de fecha
        let strategies: [JSONDecoder.DateDecodingStrategy] = [
            .iso8601,
            .secondsSince1970,
            .millisecondsSince1970,
            .deferredToDate
        ]
        
        for strategy in strategies {
            do {
                decoder.dateDecodingStrategy = strategy
                return try decoder.decode([Conversation].self, from: data)
            } catch {
                continue
            }
        }
        
        // Si todo falla, limpiar los datos corruptos
        print("⚠️ No se pudieron cargar las conversaciones, limpiando datos corruptos...")
        UserDefaults.standard.removeObject(forKey: storageKey)
        return []
    }
    
    private func saveConversationsToDisk(_ conversations: [Conversation]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(conversations)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Error saving conversations: \(error)")
        }
    }
    
    // CORRECCIÓN: Método para limpiar datos corruptos
    func clearCorruptedData() {
        storageQueue.async {
            UserDefaults.standard.removeObject(forKey: self.storageKey)
            print("✅ Datos corruptos limpiados")
        }
    }
}

// MARK: - Mock Conversation Service for Preview/Testing
#if DEBUG
class MockConversationService: ConversationServiceProtocol {
    private var conversations: [Conversation] = []
    
    func saveConversation(_ conversation: Conversation) async {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
    }
    
    func loadConversations() async -> [Conversation] {
        return conversations.sorted { $0.date > $1.date }
    }
    
    func deleteConversation(_ id: UUID) async {
        conversations.removeAll { $0.id == id }
    }
    
    func deleteAllConversations() async {
        conversations.removeAll()
    }
}
#endif

// MARK: - Preview Data
extension ConversationService {
    static var preview: ConversationServiceProtocol {
        let service = MockConversationService()
        
        let previewConversations = [
            Conversation(
                date: Date().addingTimeInterval(-3600),
                messages: [
                    ConversationMessage(
                        text: "Hola",
                        isFromUser: false,
                        timestamp: Date().addingTimeInterval(-3600),
                        confidence: 0.92
                    ),
                    ConversationMessage(
                        text: "¿Cómo estás?",
                        isFromUser: true,
                        timestamp: Date().addingTimeInterval(-3500),
                        confidence: nil
                    )
                ]
            )
        ]
        
        Task {
            for conversation in previewConversations {
                await service.saveConversation(conversation)
            }
        }
        
        return service
    }
}
