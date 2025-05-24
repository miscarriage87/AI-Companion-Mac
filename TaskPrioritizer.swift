
//
//  TaskPrioritizer.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine
import CoreML

/// TaskPrioritizer uses AI to analyze and prioritize tasks based on various factors
/// including deadlines, importance, user preferences, and contextual information.
class TaskPrioritizer {
    // MARK: - Properties
    
    private let userPreferencesManager: UserPreferencesManager
    private let contextManager: ContextManager
    private var cancellables = Set<AnyCancellable>()
    
    // ML model for task prioritization
    private var prioritizationModel: MLModel?
    
    // MARK: - Initialization
    
    init(userPreferencesManager: UserPreferencesManager, contextManager: ContextManager) {
        self.userPreferencesManager = userPreferencesManager
        self.contextManager = contextManager
        loadPrioritizationModel()
    }
    
    // MARK: - Model Loading
    
    /// Load the ML model for task prioritization
    private func loadPrioritizationModel() {
        // In a real implementation, this would load a trained CoreML model
        // For now, we'll use a rule-based approach
        print("Task prioritization model initialized")
    }
    
    // MARK: - Task Prioritization
    
    /// Prioritize a list of tasks based on various factors
    /// - Parameter tasks: Array of tasks to prioritize
    /// - Returns: Array of prioritized tasks with priority scores
    func prioritizeTasks(_ tasks: [Task]) -> [PrioritizedTask] {
        // Calculate priority scores for each task
        let prioritizedTasks = tasks.map { task -> PrioritizedTask in
            let priorityScore = calculatePriorityScore(for: task)
            return PrioritizedTask(task: task, priorityScore: priorityScore)
        }
        
        // Sort by priority score (descending)
        return prioritizedTasks.sorted { $0.priorityScore > $1.priorityScore }
    }
    
    /// Calculate a priority score for a single task
    /// - Parameter task: The task to evaluate
    /// - Returns: Priority score between 0 and 100
    private func calculatePriorityScore(for task: Task) -> Double {
        var score: Double = 0
        
        // Factor 1: Deadline proximity (0-30 points)
        if let deadline = task.deadline {
            let timeToDeadline = deadline.timeIntervalSince(Date())
            let daysToDeadline = timeToDeadline / (60 * 60 * 24)
            
            if daysToDeadline < 0 {
                // Overdue tasks get maximum urgency
                score += 30
            } else if daysToDeadline < 1 {
                // Due today
                score += 25
            } else if daysToDeadline < 3 {
                // Due in next 3 days
                score += 20
            } else if daysToDeadline < 7 {
                // Due in next week
                score += 15
            } else {
                // Due later
                score += max(0, 10 - daysToDeadline)
            }
        }
        
        // Factor 2: User-assigned importance (0-25 points)
        switch task.importance {
        case .high:
            score += 25
        case .medium:
            score += 15
        case .low:
            score += 5
        }
        
        // Factor 3: Estimated effort (0-15 points)
        // Tasks requiring moderate effort are prioritized over very quick or very long tasks
        let effortScore: Double
        switch task.estimatedDuration {
        case 0..<15: // Quick tasks (< 15 min)
            effortScore = 10
        case 15..<60: // Medium tasks (15-60 min)
            effortScore = 15
        case 60..<180: // Longer tasks (1-3 hours)
            effortScore = 12
        default: // Very long tasks (> 3 hours)
            effortScore = 8
        }
        score += effortScore
        
        // Factor 4: Dependencies (0-10 points)
        // Tasks that block other tasks get higher priority
        score += Double(task.blocksOtherTasks.count * 2)
        
        // Factor 5: User behavior patterns (0-10 points)
        score += calculateUserPatternScore(for: task)
        
        // Factor 6: Context relevance (0-10 points)
        score += calculateContextRelevanceScore(for: task)
        
        return min(score, 100) // Cap at 100
    }
    
    /// Calculate score based on user behavior patterns
    /// - Parameter task: The task to evaluate
    /// - Returns: Score component between 0 and 10
    private func calculateUserPatternScore(for task: Task) -> Double {
        // In a real implementation, this would analyze historical user data
        // For example, if user typically completes similar tasks in the morning
        
        // Mock implementation
        let taskCategory = task.category
        let preferredCategories = userPreferencesManager.getPreferredTaskCategories()
        
        if preferredCategories.contains(taskCategory) {
            return 10
        } else {
            return 5
        }
    }
    
    /// Calculate score based on current context relevance
    /// - Parameter task: The task to evaluate
    /// - Returns: Score component between 0 and 10
    private func calculateContextRelevanceScore(for task: Task) -> Double {
        let currentActivity = contextManager.getCurrentActivity()
        let currentLocation = contextManager.getCurrentLocation()
        
        var score: Double = 0
        
        // Location-based relevance
        if task.preferredLocation == currentLocation {
            score += 5
        }
        
        // Activity-based relevance
        switch currentActivity {
        case .working:
            if task.category == .work {
                score += 5
            }
        case .relaxing:
            if task.category == .personal {
                score += 5
            }
        case .commuting:
            if task.category == .learning || task.estimatedDuration < 30 {
                score += 5
            }
        case .meeting:
            if task.category == .work && task.importance == .high {
                score += 5
            }
        }
        
        return score
    }
    
    // MARK: - Task Recommendations
    
    /// Get recommended next tasks based on current context
    /// - Parameter allTasks: All available tasks
    /// - Returns: List of recommended tasks with reasons
    func getRecommendedTasks(from allTasks: [Task]) -> [TaskRecommendation] {
        let prioritizedTasks = prioritizeTasks(allTasks)
        
        // Get top 3 tasks
        let topTasks = Array(prioritizedTasks.prefix(3))
        
        // Generate recommendations with explanations
        return topTasks.map { prioritizedTask in
            let task = prioritizedTask.task
            let reason = generateRecommendationReason(for: task, score: prioritizedTask.priorityScore)
            return TaskRecommendation(task: task, reason: reason)
        }
    }
    
    /// Generate a human-readable explanation for why a task is recommended
    /// - Parameters:
    ///   - task: The recommended task
    ///   - score: The priority score
    /// - Returns: Explanation string
    private func generateRecommendationReason(for task: Task, score: Double) -> String {
        var reasons: [String] = []
        
        // Deadline-based reason
        if let deadline = task.deadline {
            let timeToDeadline = deadline.timeIntervalSince(Date())
            let daysToDeadline = timeToDeadline / (60 * 60 * 24)
            
            if daysToDeadline < 0 {
                reasons.append("This task is overdue")
            } else if daysToDeadline < 1 {
                reasons.append("This task is due today")
            } else if daysToDeadline < 3 {
                reasons.append("This task is due soon (within 3 days)")
            }
        }
        
        // Importance-based reason
        if task.importance == .high {
            reasons.append("You marked this as high importance")
        }
        
        // Dependency-based reason
        if !task.blocksOtherTasks.isEmpty {
            reasons.append("This task is blocking \(task.blocksOtherTasks.count) other task(s)")
        }
        
        // Context-based reason
        let currentLocation = contextManager.getCurrentLocation()
        if task.preferredLocation == currentLocation {
            reasons.append("This task is suitable for your current location")
        }
        
        let currentActivity = contextManager.getCurrentActivity()
        if (currentActivity == .working && task.category == .work) ||
           (currentActivity == .relaxing && task.category == .personal) {
            reasons.append("This task fits your current activity")
        }
        
        // If no specific reasons, provide a generic one
        if reasons.isEmpty {
            reasons.append("This task has a high overall priority score (\(Int(score)))")
        }
        
        return reasons.joined(separator: ". ") + "."
    }
    
    // MARK: - Fine-tuning
    
    /// Fine-tune the prioritization model based on user feedback
    /// - Parameters:
    ///   - task: The task that received feedback
    ///   - userPriority: The priority assigned by the user
    ///   - modelPriority: The priority assigned by the model
    func learnFromUserFeedback(task: Task, userPriority: Double, modelPriority: Double) {
        // In a real implementation, this would update the ML model
        // For now, we'll just log the feedback
        print("Learning from user feedback: Task '\(task.title)' - User priority: \(userPriority), Model priority: \(modelPriority)")
        
        // Update user preferences based on feedback
        if userPriority > modelPriority {
            userPreferencesManager.increasePreferenceForCategory(task.category)
        }
    }
}

// MARK: - Supporting Types

/// Represents a task to be prioritized
struct Task {
    let id: UUID
    let title: String
    let description: String
    let deadline: Date?
    let importance: TaskImportance
    let estimatedDuration: TimeInterval // in minutes
    let category: TaskCategory
    let preferredLocation: UserLocation
    let blocksOtherTasks: [UUID] // IDs of tasks that depend on this one
}

/// Task importance levels
enum TaskImportance {
    case low
    case medium
    case high
}

/// Task categories
enum TaskCategory {
    case work
    case personal
    case learning
    case health
    case social
    case other
}

/// A task with its calculated priority score
struct PrioritizedTask {
    let task: Task
    let priorityScore: Double
}

/// A recommended task with explanation
struct TaskRecommendation {
    let task: Task
    let reason: String
}
