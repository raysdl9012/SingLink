//
//  DataModels.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import Foundation
import Vision

struct HandPose: Identifiable, Codable, Equatable {
    let id: UUID
    let points: [SimulatedPoint]
    let confidence: Float
    let timestamp: Date
    
    init(id: UUID = UUID(), points: [SimulatedPoint], confidence: Float, timestamp: Date = Date()) {
        self.id = id
        self.points = points
        self.confidence = confidence
        self.timestamp = timestamp
    }
    
    static func == (lhs: HandPose, rhs: HandPose) -> Bool {
        lhs.id == rhs.id
    }
}

struct SimulatedPoint: Codable, Equatable {
    let x: Double
    let y: Double
    let confidence: Float
    let jointName: String
    
    init(x: Double, y: Double, confidence: Float, jointName: String) {
        self.x = x
        self.y = y
        self.confidence = confidence
        self.jointName = jointName
    }
}
struct SignPrediction: Identifiable, Equatable, Codable {
    let id: UUID
    let sign: String
    let confidence: Float
    let alternativePredictions: [String]
    let timestamp: Date
    
    init(id: UUID = UUID(), sign: String, confidence: Float, alternativePredictions: [String], timestamp: Date) {
        self.id = id
        self.sign = sign
        self.confidence = confidence
        self.alternativePredictions = alternativePredictions
        self.timestamp = timestamp
    }
    
    static func == (lhs: SignPrediction, rhs: SignPrediction) -> Bool {
        lhs.id == rhs.id
    }
}

struct Conversation: Identifiable, Codable {
    let id: UUID
    let date: Date
    var messages: [ConversationMessage]
    
    init(id: UUID = UUID(), date: Date, messages: [ConversationMessage]) {
        self.id = id
        self.date = date
        self.messages = messages
    }
}

struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let confidence: Float?
    
    init(id: UUID = UUID(), text: String, isFromUser: Bool, timestamp: Date, confidence: Float?) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.confidence = confidence
    }
}
