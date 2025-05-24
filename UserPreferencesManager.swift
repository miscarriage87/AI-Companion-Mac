
//
//  UserPreferencesManager.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine

/// UserPreferencesManager manages user preferences and settings
/// It provides a centralized store for user-specific configuration
class UserPreferencesManager {
    // MARK: - Properties
    
    // User profile
    private var userName: String?
    private var userEmail: String?
    
    // Preferences
    private var preferences: [String: Any] = [:]
    
    // Usage statistics
    private var interactionCount: Int = 0
    private var lastInteractionTime: Date?
    private var commandUsage: [String: Int] = [:]
    private var featurePreferences: [String: Int] = [:]
    private var topicInterests: [String: Int] = [:]
    private var contentTypePreferences: [String: Int] = [:]
    
    // Publishers
    private let preferencesUpdateSubject = PassthroughSubject<String, Never>()
    var preferencesUpdates: AnyPublisher<String, Never> {
        return preferencesUpdateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        loadPreferences()
    }
    
    // MARK: - Preference Management
    
    /// Load preferences from persistent storage
    private func loadPreferences() {
        // In a real implementation, this would load from UserDefaults or a database
        // For now, we'll initialize with default values
        preferences = [
            "colorScheme": "system",
            "fontSize": "medium",
            "notificationsEnabled": true,
            "preferredResponseStyle": "conversational",
            "preferredTaskCategories": ["work", "personal"],
            "peakUsageHours": [9, 14, 20],
            "topFeatures": ["calendar", "tasks", "weather"],
            "preferredTopics": ["technology", "productivity"],
            "averageSessionDuration": 15.0 // minutes
        ]
    }
    
    /// Save preferences to persistent storage
    private func savePreferences() {
        // In a real implementation, this would save to UserDefaults or a database
        // For now, we'll just print the preferences
        print("Saving preferences: \(preferences)")
    }
    
    /// Set a preference value
    /// - Parameters:
    ///   - value: The value to set
    ///   - key: The preference key
    func setPreference(_ value: Any, forKey key: String) {
        preferences[key] = value
        savePreferences()
        preferencesUpdateSubject.send(key)
    }
    
    /// Get a preference value
    /// - Parameter key: The preference key
    /// - Returns: The preference value if found
    func getPreference(forKey key: String) -> Any? {
        return preferences[key]
    }
    
    // MARK: - User Profile
    
    /// Set the user's name
    /// - Parameter name: The user's name
    func setUserName(_ name: String) {
        userName = name
        setPreference(name, forKey: "userName")
    }
    
    /// Get the user's name
    /// - Returns: The user's name if set
    func getUserName() -> String? {
        return userName ?? preferences["userName"] as? String
    }
    
    /// Set the user's email
    /// - Parameter email: The user's email
    func setUserEmail(_ email: String) {
        userEmail = email
        setPreference(email, forKey: "userEmail")
    }
    
    /// Get the user's email
    /// - Returns: The user's email if set
    func getUserEmail() -> String? {
        return userEmail ?? preferences["userEmail"] as? String
    }
    
    // MARK: - UI Preferences
    
    /// Set the preferred color scheme
    /// - Parameter scheme: The color scheme (system, light, dark)
    func setPreferredColorScheme(_ scheme: String) {
        setPreference(scheme, forKey: "colorScheme")
    }
    
    /// Get the preferred color scheme
    /// - Returns: The color scheme if set
    func getPreferredColorScheme() -> String? {
        return preferences["colorScheme"] as? String
    }
    
    /// Set the preferred font size
    /// - Parameter size: The font size (small, medium, large)
    func setPreferredFontSize(_ size: String) {
        setPreference(size, forKey: "fontSize")
    }
    
    /// Get the preferred font size
    /// - Returns: The font size if set
    func getPreferredFontSize() -> String? {
        return preferences["fontSize"] as? String
    }
    
    /// Set the preferred layout
    /// - Parameter layout: The layout (standard, compact, expanded)
    func setPreferredLayout(_ layout: String) {
        setPreference(layout, forKey: "layout")
    }
    
    /// Get the preferred layout
    /// - Returns: The layout if set
    func getPreferredLayout() -> String? {
        return preferences["layout"] as? String
    }
    
    // MARK: - Response Preferences
    
    /// Set the preferred response style
    /// - Parameter style: The response style
    func setPreferredResponseStyle(_ style: ResponseStyle) {
        setPreference(style.rawValue, forKey: "preferredResponseStyle")
    }
    
    /// Get the preferred response style
    /// - Returns: The response style if set
    func getPreferredResponseStyle() -> ResponseStyle? {
        guard let styleString = preferences["preferredResponseStyle"] as? String,
              let style = ResponseStyle(rawValue: styleString) else {
            return nil
        }
        return style
    }
    
    // MARK: - Task Preferences
    
    /// Set preferred task categories
    /// - Parameter categories: Array of task categories
    func setPreferredTaskCategories(_ categories: [String]) {
        setPreference(categories, forKey: "preferredTaskCategories")
    }
    
    /// Get preferred task categories
    /// - Returns: Array of task categories
    func getPreferredTaskCategories() -> [String] {
        return preferences["preferredTaskCategories"] as? [String] ?? []
    }
    
    /// Increase preference for a task category
    /// - Parameter category: The category to increase preference for
    func increasePreferenceForCategory(_ category: TaskCategory) {
        var categories = getPreferredTaskCategories()
        let categoryString = String(describing: category)
        
        if !categories.contains(categoryString) {
            categories.append(categoryString)
            setPreferredTaskCategories(categories)
        }
    }
    
    // MARK: - Usage Statistics
    
    /// Increment the interaction count
    func incrementInteractionCount() {
        interactionCount += 1
        setPreference(interactionCount, forKey: "interactionCount")
    }
    
    /// Get the interaction count
    /// - Returns: The number of interactions
    func getInteractionCount() -> Int {
        return interactionCount
    }
    
    /// Set the last interaction time
    /// - Parameter time: The interaction time
    func setLastInteractionTime(_ time: Date) {
        lastInteractionTime = time
        setPreference(time, forKey: "lastInteractionTime")
    }
    
    /// Get the last interaction time
    /// - Returns: The last interaction time if available
    func getLastInteractionTime() -> Date? {
        return lastInteractionTime
    }
    
    /// Increment usage count for a command
    /// - Parameter command: The command used
    func incrementCommandUsage(_ command: String) {
        commandUsage[command, default: 0] += 1
        setPreference(commandUsage, forKey: "commandUsage")
    }
    
    /// Get usage count for a command
    /// - Parameter command: The command to check
    /// - Returns: The usage count
    func getCommandUsage(_ command: String) -> Int {
        return commandUsage[command] ?? 0
    }
    
    /// Increment preference for a feature
    /// - Parameter feature: The feature used
    func incrementFeaturePreference(_ feature: String) {
        featurePreferences[feature, default: 0] += 1
        setPreference(featurePreferences, forKey: "featurePreferences")
    }
    
    /// Decrement preference for a feature
    /// - Parameter feature: The feature to decrement
    func decrementFeaturePreference(_ feature: String) {
        featurePreferences[feature, default: 0] = max(0, (featurePreferences[feature] ?? 0) - 1)
        setPreference(featurePreferences, forKey: "featurePreferences")
    }
    
    /// Get preference level for a feature
    /// - Parameter feature: The feature to check
    /// - Returns: The preference level
    func getFeaturePreference(_ feature: String) -> Int {
        return featurePreferences[feature] ?? 0
    }
    
    /// Increment interest in a topic
    /// - Parameter topic: The topic of interest
    func incrementTopicInterest(_ topic: String) {
        topicInterests[topic, default: 0] += 1
        setPreference(topicInterests, forKey: "topicInterests")
    }
    
    /// Get interest level for a topic
    /// - Parameter topic: The topic to check
    /// - Returns: The interest level
    func getTopicInterest(_ topic: String) -> Int {
        return topicInterests[topic] ?? 0
    }
    
    /// Increment preference for a content type
    /// - Parameter contentType: The content type
    func incrementContentTypePreference(_ contentType: String) {
        contentTypePreferences[contentType, default: 0] += 1
        setPreference(contentTypePreferences, forKey: "contentTypePreferences")
    }
    
    /// Get preference level for a content type
    /// - Parameter contentType: The content type to check
    /// - Returns: The preference level
    func getContentTypePreference(_ contentType: String) -> Int {
        return contentTypePreferences[contentType] ?? 0
    }
    
    // MARK: - Behavior Analysis
    
    /// Set peak usage hours
    /// - Parameter hours: Array of peak hours (0-23)
    func setPeakUsageHours(_ hours: [Int]) {
        setPreference(hours, forKey: "peakUsageHours")
    }
    
    /// Get peak usage hours
    /// - Returns: Array of peak hours
    func getPeakUsageHours() -> [Int] {
        return preferences["peakUsageHours"] as? [Int] ?? []
    }
    
    /// Set top features
    /// - Parameter features: Array of top features
    func setTopFeatures(_ features: [String]) {
        setPreference(features, forKey: "topFeatures")
    }
    
    /// Get top features
    /// - Returns: Array of top features
    func getTopFeatures() -> [String] {
        return preferences["topFeatures"] as? [String] ?? []
    }
    
    /// Set preferred topics
    /// - Parameter topics: Array of preferred topics
    func setPreferredTopics(_ topics: [String]) {
        setPreference(topics, forKey: "preferredTopics")
    }
    
    /// Get preferred topics
    /// - Returns: Array of preferred topics
    func getPreferredTopics() -> [String] {
        return preferences["preferredTopics"] as? [String] ?? []
    }
    
    /// Set average session duration
    /// - Parameter duration: Average duration in minutes
    func setAverageSessionDuration(_ duration: Double) {
        setPreference(duration, forKey: "averageSessionDuration")
    }
    
    /// Get average session duration
    /// - Returns: Average duration in minutes
    func getAverageSessionDuration() -> Double {
        return preferences["averageSessionDuration"] as? Double ?? 0
    }
    
    // MARK: - Feedback
    
    /// Record a feedback rating
    /// - Parameter rating: Rating value (1-5)
    func recordFeedbackRating(_ rating: Int) {
        var ratings = preferences["feedbackRatings"] as? [Int] ?? []
        ratings.append(rating)
        setPreference(ratings, forKey: "feedbackRatings")
    }
    
    /// Get average feedback rating
    /// - Returns: Average rating
    func getAverageFeedbackRating() -> Double {
        guard let ratings = preferences["feedbackRatings"] as? [Int], !ratings.isEmpty else {
            return 0
        }
        
        let sum = ratings.reduce(0, +)
        return Double(sum) / Double(ratings.count)
    }
    
    /// Record conversation sentiment
    /// - Parameter sentiment: Sentiment value (positive, negative, neutral)
    func recordConversationSentiment(_ sentiment: String) {
        var sentiments = preferences["conversationSentiments"] as? [String] ?? []
        sentiments.append(sentiment)
        setPreference(sentiments, forKey: "conversationSentiments")
    }
    
    /// Get sentiment distribution
    /// - Returns: Dictionary of sentiment counts
    func getSentimentDistribution() -> [String: Int] {
        guard let sentiments = preferences["conversationSentiments"] as? [String] else {
            return [:]
        }
        
        var distribution: [String: Int] = [:]
        for sentiment in sentiments {
            distribution[sentiment, default: 0] += 1
        }
        
        return distribution
    }
}
