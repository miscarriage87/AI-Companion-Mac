
//
//  SmartScheduler.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import EventKit
import Combine

/// SmartScheduler provides AI-powered task scheduling capabilities
/// It analyzes user patterns, calendar availability, and task priorities
/// to intelligently schedule tasks at optimal times.
class SmartScheduler {
    // MARK: - Properties
    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()
    private let userPreferencesManager: UserPreferencesManager
    private let contextManager: ContextManager
    
    // Calendar access status
    private var calendarAccessGranted = false
    
    // MARK: - Initialization
    
    init(userPreferencesManager: UserPreferencesManager, contextManager: ContextManager) {
        self.userPreferencesManager = userPreferencesManager
        self.contextManager = contextManager
        requestCalendarAccess()
    }
    
    // MARK: - Calendar Access
    
    /// Request access to the user's calendar
    private func requestCalendarAccess() {
        Task {
            do {
                if #available(macOS 14.0, *) {
                    let accessGranted = try await eventStore.requestFullAccessToEvents()
                    self.calendarAccessGranted = accessGranted
                } else {
                    // For older macOS versions
                    eventStore.requestAccess(to: .event) { [weak self] granted, error in
                        DispatchQueue.main.async {
                            self?.calendarAccessGranted = granted
                            if let error = error {
                                print("Calendar access error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } catch {
                print("Failed to request calendar access: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Task Scheduling
    
    /// Schedule a task at the optimal time based on AI analysis
    /// - Parameters:
    ///   - task: The task to schedule
    ///   - deadline: Optional deadline for the task
    ///   - duration: Estimated duration in minutes
    ///   - priority: Task priority level
    /// - Returns: Proposed scheduled time for the task
    func scheduleTask(title: String, deadline: Date?, duration: Int, priority: TaskPriority) -> Date? {
        guard calendarAccessGranted else {
            print("Calendar access not granted")
            return nil
        }
        
        // Get user's available time slots
        let availableSlots = findAvailableTimeSlots(duration: duration)
        
        // Get user's productivity patterns
        let productivityPatterns = analyzeProductivityPatterns()
        
        // Find optimal time slot based on productivity patterns, priority, and deadline
        let optimalSlot = findOptimalTimeSlot(
            availableSlots: availableSlots,
            productivityPatterns: productivityPatterns,
            priority: priority,
            deadline: deadline,
            duration: duration
        )
        
        // Create calendar event if optimal slot found
        if let optimalSlot = optimalSlot {
            createCalendarEvent(title: title, startDate: optimalSlot, duration: duration)
            return optimalSlot
        }
        
        return nil
    }
    
    /// Find available time slots in the user's calendar
    /// - Parameter duration: Required duration in minutes
    /// - Returns: Array of available time slots
    private func findAvailableTimeSlots(duration: Int) -> [Date] {
        // Get current date and time
        let now = Date()
        
        // Look ahead for the next 7 days
        guard let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now) else {
            return []
        }
        
        // Get all events in the date range
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Convert events to busy time slots
        let busySlots = events.map { event -> (start: Date, end: Date) in
            return (event.startDate, event.endDate)
        }
        
        // Find available slots (simplified algorithm)
        var availableSlots: [Date] = []
        var currentDate = now
        
        // Check every hour for the next 7 days
        while currentDate < endDate {
            let slotEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: currentDate)!
            
            // Check if this slot overlaps with any busy slot
            let isOverlapping = busySlots.contains { busySlot in
                return (currentDate < busySlot.end && slotEndDate > busySlot.start)
            }
            
            if !isOverlapping {
                // Check if it's within working hours (9 AM to 6 PM)
                let hour = Calendar.current.component(.hour, from: currentDate)
                if hour >= 9 && hour < 18 {
                    availableSlots.append(currentDate)
                }
            }
            
            // Move to next hour
            currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        }
        
        return availableSlots
    }
    
    /// Analyze user's productivity patterns based on historical data
    /// - Returns: Dictionary mapping hours of day to productivity scores
    private func analyzeProductivityPatterns() -> [Int: Double] {
        // In a real implementation, this would analyze completed tasks and their timestamps
        // For now, return a mock pattern where mornings are more productive
        return [
            9: 0.8,
            10: 0.9,
            11: 0.95,
            12: 0.7,
            13: 0.6,
            14: 0.75,
            15: 0.8,
            16: 0.7,
            17: 0.6
        ]
    }
    
    /// Find the optimal time slot based on various factors
    /// - Parameters:
    ///   - availableSlots: Available time slots
    ///   - productivityPatterns: User's productivity patterns
    ///   - priority: Task priority
    ///   - deadline: Optional deadline
    ///   - duration: Task duration in minutes
    /// - Returns: Optimal start time for the task
    private func findOptimalTimeSlot(
        availableSlots: [Date],
        productivityPatterns: [Int: Double],
        priority: TaskPriority,
        deadline: Date?,
        duration: Int
    ) -> Date? {
        // If no available slots, return nil
        if availableSlots.isEmpty {
            return nil
        }
        
        // If high priority task with deadline approaching, schedule ASAP
        if priority == .high, let deadline = deadline {
            let timeToDeadline = deadline.timeIntervalSince(Date())
            let daysToDeadline = timeToDeadline / (60 * 60 * 24)
            
            if daysToDeadline < 1 {
                return availableSlots.first
            }
        }
        
        // Score each available slot based on productivity patterns and other factors
        var scoredSlots: [(slot: Date, score: Double)] = []
        
        for slot in availableSlots {
            let hour = Calendar.current.component(.hour, from: slot)
            let productivityScore = productivityPatterns[hour] ?? 0.5
            
            var score = productivityScore
            
            // Factor in deadline if exists
            if let deadline = deadline {
                let timeToDeadline = deadline.timeIntervalSince(slot)
                // Prefer slots that are not too close to the deadline
                if timeToDeadline > 0 {
                    let daysToDeadline = timeToDeadline / (60 * 60 * 24)
                    if daysToDeadline < 1 {
                        score += 0.3 // Boost score for tasks due soon
                    }
                } else {
                    score = 0 // Past deadline, not a valid slot
                }
            }
            
            // Factor in priority
            switch priority {
            case .high:
                score *= 1.5
            case .medium:
                score *= 1.2
            case .low:
                score *= 1.0
            }
            
            // Factor in current context from ContextManager
            let currentActivity = contextManager.getCurrentActivity()
            let currentLocation = contextManager.getCurrentLocation()
            
            // If user is in a focused work context, boost score for complex tasks
            if currentActivity == .working && duration > 30 {
                score += 0.2
            }
            
            // If user is at home, boost score for personal tasks
            if currentLocation == .home {
                score += 0.1
            }
            
            scoredSlots.append((slot, score))
        }
        
        // Sort by score and return the highest-scoring slot
        scoredSlots.sort { $0.score > $1.score }
        return scoredSlots.first?.slot
    }
    
    /// Create a calendar event for the scheduled task
    /// - Parameters:
    ///   - title: Event title
    ///   - startDate: Start date and time
    ///   - duration: Duration in minutes
    /// - Returns: Success status
    @discardableResult
    private func createCalendarEvent(title: String, startDate: Date, duration: Int) -> Bool {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Daily Planning
    
    /// Generate a daily plan based on scheduled tasks and calendar events
    /// - Returns: Structured daily plan
    func generateDailyPlan() -> DailyPlan {
        guard calendarAccessGranted else {
            return DailyPlan(date: Date(), events: [], tasks: [])
        }
        
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Get all events for today
        let predicate = eventStore.predicateForEvents(withStart: today, end: tomorrow, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Convert to DailyPlanItem objects
        let planItems = events.map { event in
            return DailyPlanItem(
                title: event.title,
                startTime: event.startDate,
                endTime: event.endDate,
                type: .event,
                priority: .medium,
                notes: event.notes ?? ""
            )
        }
        
        // In a real implementation, we would also fetch tasks from a task manager
        // and include them in the plan
        
        return DailyPlan(
            date: today,
            events: planItems.filter { $0.type == .event },
            tasks: planItems.filter { $0.type == .task }
        )
    }
    
    /// Generate a summary of the day's activities and accomplishments
    /// - Returns: Daily summary text
    func generateDailySummary() -> String {
        let plan = generateDailyPlan()
        
        var summary = "Daily Summary for \(formatDate(plan.date)):\n\n"
        
        // Summarize events
        summary += "Events:\n"
        if plan.events.isEmpty {
            summary += "- No events scheduled\n"
        } else {
            for event in plan.events {
                summary += "- \(event.title) (\(formatTime(event.startTime)) - \(formatTime(event.endTime)))\n"
            }
        }
        
        summary += "\nTasks:\n"
        if plan.tasks.isEmpty {
            summary += "- No tasks scheduled\n"
        } else {
            for task in plan.tasks {
                summary += "- \(task.title) (\(formatTime(task.startTime)))\n"
            }
        }
        
        // Add productivity insights
        summary += "\nProductivity Insights:\n"
        summary += "- Most productive time: \(getMostProductiveTime())\n"
        summary += "- Suggested focus time: \(getSuggestedFocusTime())\n"
        
        return summary
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getMostProductiveTime() -> String {
        let patterns = analyzeProductivityPatterns()
        if let mostProductiveHour = patterns.max(by: { $0.value < $1.value })?.key {
            return "\(mostProductiveHour):00 - \(mostProductiveHour + 1):00"
        }
        return "Not enough data"
    }
    
    private func getSuggestedFocusTime() -> String {
        // In a real implementation, this would analyze calendar and suggest
        // the best time block for focused work
        return "10:00 AM - 12:00 PM"
    }
}

// MARK: - Supporting Types

/// Task priority levels
enum TaskPriority {
    case low
    case medium
    case high
}

/// Types of daily plan items
enum DailyPlanItemType {
    case task
    case event
}

/// Represents an item in the daily plan (task or event)
struct DailyPlanItem {
    let title: String
    let startTime: Date
    let endTime: Date
    let type: DailyPlanItemType
    let priority: TaskPriority
    let notes: String
}

/// Represents a complete daily plan
struct DailyPlan {
    let date: Date
    let events: [DailyPlanItem]
    let tasks: [DailyPlanItem]
}
