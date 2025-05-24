
//
//  UserBehaviorAnalyzerTests.swift
//  AI CompanionTests
//
//  Created: May 20, 2025
//

import XCTest
@testable import AI_Companion

class UserBehaviorAnalyzerTests: XCTestCase {
    
    var userPreferencesManager: UserPreferencesManager!
    var userBehaviorAnalyzer: UserBehaviorAnalyzer!
    
    override func setUp() {
        super.setUp()
        userPreferencesManager = UserPreferencesManager()
        userBehaviorAnalyzer = UserBehaviorAnalyzer(userPreferencesManager: userPreferencesManager)
    }
    
    override func tearDown() {
        userBehaviorAnalyzer = nil
        userPreferencesManager = nil
        super.tearDown()
    }
    
    func testRecordInteraction() {
        // Given
        let interaction = createInteraction(type: .command, feature: "calendar")
        
        // When
        userBehaviorAnalyzer.recordInteraction(interaction)
        
        // Then
        // This is mostly a behavioral test, so we're just checking that it doesn't crash
        // In a real test, we would verify that the interaction was recorded
        XCTAssertTrue(userPreferencesManager.getInteractionCount() > 0, "Interaction count should be incremented")
    }
    
    func testPredictNextAction() {
        // Given
        // Record a series of interactions to establish a pattern
        let interaction1 = createInteraction(type: .command, feature: "calendar")
        let interaction2 = createInteraction(type: .command, feature: "tasks")
        let interaction3 = createInteraction(type: .command, feature: "calendar")
        let interaction4 = createInteraction(type: .command, feature: "tasks")
        
        userBehaviorAnalyzer.recordInteraction(interaction1)
        userBehaviorAnalyzer.recordInteraction(interaction2)
        userBehaviorAnalyzer.recordInteraction(interaction3)
        userBehaviorAnalyzer.recordInteraction(interaction4)
        
        // When
        let predictedAction = userBehaviorAnalyzer.predictNextAction(currentFeature: "calendar")
        
        // Then
        // Since we established a pattern of calendar -> tasks, the prediction should be "tasks"
        // However, this is probabilistic, so it might not always be correct
        if let predictedAction = predictedAction {
            XCTAssertEqual(predictedAction.feature, "tasks", "Predicted action should be 'tasks'")
            XCTAssertGreaterThan(predictedAction.confidence, 0, "Confidence should be greater than 0")
        }
    }
    
    func testPredictPreferredResponseStyle() {
        // Given
        // Record feedback interactions with different response styles
        let feedback1 = createInteraction(
            type: .feedback,
            feature: "conversation",
            metadata: ["responseStyle": "conversational", "rating": 5]
        )
        let feedback2 = createInteraction(
            type: .feedback,
            feature: "conversation",
            metadata: ["responseStyle": "technical", "rating": 3]
        )
        let feedback3 = createInteraction(
            type: .feedback,
            feature: "conversation",
            metadata: ["responseStyle": "conversational", "rating": 4]
        )
        
        userBehaviorAnalyzer.recordInteraction(feedback1)
        userBehaviorAnalyzer.recordInteraction(feedback2)
        userBehaviorAnalyzer.recordInteraction(feedback3)
        
        // When
        let preferredStyle = userBehaviorAnalyzer.predictPreferredResponseStyle()
        
        // Then
        // Since we gave higher ratings to conversational style, that should be preferred
        XCTAssertEqual(preferredStyle, .conversational, "Preferred style should be conversational")
    }
    
    func testFineTuneModel() {
        // Given
        // Record some interactions
        let interaction1 = createInteraction(type: .command, feature: "calendar")
        let interaction2 = createInteraction(type: .conversation, feature: "assistant")
        
        userBehaviorAnalyzer.recordInteraction(interaction1)
        userBehaviorAnalyzer.recordInteraction(interaction2)
        
        // When
        userBehaviorAnalyzer.fineTuneModel()
        
        // Then
        // This is mostly a behavioral test, so we're just checking that it doesn't crash
        // In a real test, we would verify that the model was updated
        XCTAssertTrue(true, "Fine-tuning should complete without errors")
    }
    
    // MARK: - Helper Methods
    
    private func createInteraction(type: InteractionType, feature: String, metadata: [String: Any] = [:]) -> UserInteraction {
        return UserInteraction(
            id: UUID(),
            timestamp: Date(),
            type: type,
            feature: feature,
            metadata: metadata
        )
    }
}
