
//
//  UserBehaviorAnalyzer.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine
import CoreML

/// UserBehaviorAnalyzer learns from user interactions to improve personalization
/// It tracks patterns, preferences, and behaviors to adapt the AI companion's responses
class UserBehaviorAnalyzer {
    // MARK: - Properties
    
    private let userPreferencesManager: UserPreferencesManager
    private var cancellables = Set<AnyCancellable>()
    
    // Behavior tracking
    private var interactionHistory: [UserInteraction] = []
    private var patternRecognitionModel: MLModel?
    
    // Publishers
    private let interactionSubject = PassthroughSubject<UserInteraction, Never>()
    
    // MARK: - Initialization
    
    init(userPreferencesManager: UserPreferencesManager) {
        self.userPreferencesManager = userPreferencesManager
        setupSubscriptions()
        loadPatternRecognitionModel()
        loadInteractionHistory()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Process and store each interaction
        interactionSubject
            .sink { [weak self] interaction in
                self?.processInteraction(interaction)
            }
            .store(in: &cancellables)
    }
    
    private func loadPatternRecognitionModel() {
        // In a real implementation, this would load a CoreML model
        // For now, we'll use rule-based pattern recognition
        print("Pattern recognition model initialized")
    }
    
    private func loadInteractionHistory() {
        // In a real implementation, this would load from persistent storage
        // For now, we'll start with an empty history
        interactionHistory = []
    }
    
    // MARK: - Interaction Tracking
    
    /// Record a new user interaction
    /// - Parameter interaction: The interaction to record
    func recordInteraction(_ interaction: UserInteraction) {
        interactionSubject.send(interaction)
    }
    
    /// Process and analyze a user interaction
    /// - Parameter interaction: The interaction to process
    private func processInteraction(_ interaction: UserInteraction) {
        // Add to history
        interactionHistory.append(interaction)
        
        // Save to persistent storage (in a real implementation)
        saveInteractionHistory()
        
        // Analyze for patterns
        analyzePatterns()
        
        // Update user preferences based on interaction
        updatePreferencesFromInteraction(interaction)
    }
    
    /// Save interaction history to persistent storage
    private func saveInteractionHistory() {
        // In a real implementation, this would save to disk or database
        // For now, we'll just keep in memory
        
        // Limit history size to prevent memory issues
        if interactionHistory.count > 1000 {
            interactionHistory = Array(interactionHistory.suffix(1000))
        }
    }
    
    // MARK: - Pattern Analysis
    
    /// Analyze interaction history for patterns
    private func analyzePatterns() {
        // Analyze time-of-day patterns
        analyzeTimeOfDayPatterns()
        
        // Analyze feature usage patterns
        analyzeFeatureUsagePatterns()
        
        // Analyze content preferences
        analyzeContentPreferences()
        
        // Analyze interaction duration
        analyzeInteractionDuration()
    }
    
    /// Analyze when the user typically interacts with the app
    private func analyzeTimeOfDayPatterns() {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        // Count interactions by hour of day
        for interaction in interactionHistory {
            let hour = calendar.component(.hour, from: interaction.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        
        // Find peak usage hours (top 3)
        let sortedHours = hourCounts.sorted { $0.value > $1.value }
        let peakHours = sortedHours.prefix(3).map { $0.key }
        
        // Update user preferences with peak hours
        userPreferencesManager.setPeakUsageHours(peakHours)
    }
    
    /// Analyze which features the user uses most frequently
    private func analyzeFeatureUsagePatterns() {
        var featureCounts: [String: Int] = [:]
        
        // Count interactions by feature
        for interaction in interactionHistory {
            featureCounts[interaction.feature, default: 0] += 1
        }
        
        // Find most used features (top 5)
        let sortedFeatures = featureCounts.sorted { $0.value > $1.value }
        let topFeatures = sortedFeatures.prefix(5).map { $0.key }
        
        // Update user preferences with top features
        userPreferencesManager.setTopFeatures(topFeatures)
    }
    
    /// Analyze user's content preferences
    private func analyzeContentPreferences() {
        // Extract content topics from interactions
        let contentInteractions = interactionHistory.filter { $0.type == .contentRequest }
        
        var topicCounts: [String: Int] = [:]
        
        // Count interactions by topic
        for interaction in contentInteractions {
            if let topic = interaction.metadata["topic"] as? String {
                topicCounts[topic, default: 0] += 1
            }
        }
        
        // Find preferred topics (top 5)
        let sortedTopics = topicCounts.sorted { $0.value > $1.value }
        let preferredTopics = sortedTopics.prefix(5).map { $0.key }
        
        // Update user preferences with preferred topics
        userPreferencesManager.setPreferredTopics(preferredTopics)
    }
    
    /// Analyze typical interaction duration
    private func analyzeInteractionDuration() {
        // Group interactions into sessions
        let sessions = groupInteractionsIntoSessions()
        
        // Calculate average session duration
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let averageDuration = sessions.isEmpty ? 0 : totalDuration / Double(sessions.count)
        
        // Update user preferences with average session duration
        userPreferencesManager.setAverageSessionDuration(averageDuration)
    }
    
    /// Group interactions into sessions (interactions close in time)
    /// - Returns: Array of user sessions
    private func groupInteractionsIntoSessions() -> [UserSession] {
        guard !interactionHistory.isEmpty else { return [] }
        
        // Sort interactions by timestamp
        let sortedInteractions = interactionHistory.sorted { $0.timestamp < $1.timestamp }
        
        var sessions: [UserSession] = []
        var currentSessionInteractions: [UserInteraction] = [sortedInteractions[0]]
        var currentSessionStart = sortedInteractions[0].timestamp
        
        // Group interactions with less than 5 minutes between them
        for i in 1..<sortedInteractions.count {
            let interaction = sortedInteractions[i]
            let previousInteraction = sortedInteractions[i-1]
            
            let timeDifference = interaction.timestamp.timeIntervalSince(previousInteraction.timestamp)
            
            if timeDifference > 300 { // 5 minutes = 300 seconds
                // End current session and start a new one
                let sessionDuration = previousInteraction.timestamp.timeIntervalSince(currentSessionStart)
                sessions.append(UserSession(
                    startTime: currentSessionStart,
                    endTime: previousInteraction.timestamp,
                    duration: sessionDuration,
                    interactions: currentSessionInteractions
                ))
                
                currentSessionInteractions = [interaction]
                currentSessionStart = interaction.timestamp
            } else {
                // Add to current session
                currentSessionInteractions.append(interaction)
            }
        }
        
        // Add the last session
        if !currentSessionInteractions.isEmpty {
            let lastInteraction = currentSessionInteractions.last!
            let sessionDuration = lastInteraction.timestamp.timeIntervalSince(currentSessionStart)
            sessions.append(UserSession(
                startTime: currentSessionStart,
                endTime: lastInteraction.timestamp,
                duration: sessionDuration,
                interactions: currentSessionInteractions
            ))
        }
        
        return sessions
    }
    
    // MARK: - Preference Updates
    
    /// Update user preferences based on a single interaction
    /// - Parameter interaction: The interaction to analyze
    private func updatePreferencesFromInteraction(_ interaction: UserInteraction) {
        // Update interaction count
        userPreferencesManager.incrementInteractionCount()
        
        // Update last interaction time
        userPreferencesManager.setLastInteractionTime(interaction.timestamp)
        
        // Update feature-specific preferences
        switch interaction.type {
        case .command:
            processCommandInteraction(interaction)
        case .conversation:
            processConversationInteraction(interaction)
        case .contentRequest:
            processContentRequestInteraction(interaction)
        case .feedback:
            processFeedbackInteraction(interaction)
        }
    }
    
    private func processCommandInteraction(_ interaction: UserInteraction) {
        // Track command usage
        if let command = interaction.metadata["command"] as? String {
            userPreferencesManager.incrementCommandUsage(command)
        }
    }
    
    private func processConversationInteraction(_ interaction: UserInteraction) {
        // Track conversation topics and sentiment
        if let topic = interaction.metadata["topic"] as? String {
            userPreferencesManager.incrementTopicInterest(topic)
        }
        
        if let sentiment = interaction.metadata["sentiment"] as? String {
            userPreferencesManager.recordConversationSentiment(sentiment)
        }
    }
    
    private func processContentRequestInteraction(_ interaction: UserInteraction) {
        // Track content preferences
        if let contentType = interaction.metadata["contentType"] as? String {
            userPreferencesManager.incrementContentTypePreference(contentType)
        }
        
        if let topic = interaction.metadata["topic"] as? String {
            userPreferencesManager.incrementTopicInterest(topic)
        }
    }
    
    private func processFeedbackInteraction(_ interaction: UserInteraction) {
        // Process user feedback to improve the system
        if let rating = interaction.metadata["rating"] as? Int {
            userPreferencesManager.recordFeedbackRating(rating)
        }
        
        if let feature = interaction.metadata["feature"] as? String {
            if let isPositive = interaction.metadata["isPositive"] as? Bool, isPositive {
                userPreferencesManager.incrementFeaturePreference(feature)
            } else {
                userPreferencesManager.decrementFeaturePreference(feature)
            }
        }
    }
    
    // MARK: - Behavior Predictions
    
    /// Predict the next likely user action based on current context and history
    /// - Parameter currentFeature: The feature currently being used
    /// - Returns: Predicted next action
    func predictNextAction(currentFeature: String) -> PredictedAction? {
        // Get recent interactions
        let recentInteractions = Array(interactionHistory.suffix(20))
        
        // Find patterns where the user was in the current feature
        let relevantPatterns = recentInteractions.windows(ofCount: 2).filter { window in
            return window.first?.feature == currentFeature
        }
        
        // Count subsequent actions
        var nextActionCounts: [String: Int] = [:]
        for window in relevantPatterns {
            let nextFeature = Array(window)[1].feature
            nextActionCounts[nextFeature, default: 0] += 1
        }
        
        // Find most likely next action
        if let (nextFeature, count) = nextActionCounts.max(by: { $0.value < $1.value }),
           count > 0 {
            let confidence = Double(count) / Double(relevantPatterns.count)
            return PredictedAction(feature: nextFeature, confidence: confidence)
        }
        
        return nil
    }
    
    /// Predict user's preferred response style based on interaction history
    /// - Returns: Preferred response style
    func predictPreferredResponseStyle() -> ResponseStyle {
        // Analyze feedback on different response styles
        let feedbackInteractions = interactionHistory.filter { $0.type == .feedback }
        
        var styleRatings: [ResponseStyle: [Int]] = [
            .concise: [],
            .detailed: [],
            .conversational: [],
            .technical: []
        ]
        
        // Collect ratings for each style
        for interaction in feedbackInteractions {
            if let style = interaction.metadata["responseStyle"] as? String,
               let rating = interaction.metadata["rating"] as? Int {
                if let responseStyle = ResponseStyle(rawValue: style) {
                    styleRatings[responseStyle, default: []].append(rating)
                }
            }
        }
        
        // Calculate average rating for each style
        var averageRatings: [ResponseStyle: Double] = [:]
        for (style, ratings) in styleRatings {
            if !ratings.isEmpty {
                let average = Double(ratings.reduce(0, +)) / Double(ratings.count)
                averageRatings[style] = average
            }
        }
        
        // Return style with highest average rating, or default if no data
        if let (preferredStyle, _) = averageRatings.max(by: { $0.value < $1.value }) {
            return preferredStyle
        }
        
        // Default to conversational if no data
        return .conversational
    }
    
    // MARK: - Model Fine-tuning
    
    /// Fine-tune the behavior analysis model based on recent interactions
    func fineTuneModel() {
        // In a real implementation, this would update the CoreML model
        // For now, we'll just log the fine-tuning
        print("Fine-tuning user behavior model with \(interactionHistory.count) interactions")
        
        // Update user preferences with latest analysis
        analyzePatterns()
    }
}

// MARK: - Supporting Types

/// Types of user interactions
enum InteractionType {
    case command
    case conversation
    case contentRequest
    case feedback
}

/// Represents a single user interaction with the app
struct UserInteraction {
    let id: UUID
    let timestamp: Date
    let type: InteractionType
    let feature: String
    let metadata: [String: Any]
}

/// Represents a session of user interactions
struct UserSession {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let interactions: [UserInteraction]
}

/// Predicted next user action
struct PredictedAction {
    let feature: String
    let confidence: Double
}

/// Response styles for AI companion
enum ResponseStyle: String {
    case concise
    case detailed
    case conversational
    case technical
}

// MARK: - Extensions

extension Array {
    /// Returns sliding windows of specified count
    func windows(ofCount count: Int) -> [ArraySlice<Element>] {
        guard count > 0, self.count >= count else { return [] }
        return (0...(self.count - count)).map { i in
            self[i..<(i + count)]
        }
    }
}
