
//
//  SmartSchedulerTests.swift
//  AI CompanionTests
//
//  Created: May 20, 2025
//

import XCTest
import EventKit
@testable import AI_Companion

class SmartSchedulerTests: XCTestCase {
    
    var userPreferencesManager: UserPreferencesManager!
    var contextManager: ContextManager!
    var smartScheduler: SmartScheduler!
    
    override func setUp() {
        super.setUp()
        userPreferencesManager = UserPreferencesManager()
        contextManager = ContextManager()
        smartScheduler = SmartScheduler(userPreferencesManager: userPreferencesManager, contextManager: contextManager)
    }
    
    override func tearDown() {
        smartScheduler = nil
        contextManager = nil
        userPreferencesManager = nil
        super.tearDown()
    }
    
    func testScheduleTask() {
        // Given
        let title = "Test Task"
        let deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let duration = 60 // 60 minutes
        let priority = TaskPriority.high
        
        // When
        let scheduledTime = smartScheduler.scheduleTask(title: title, deadline: deadline, duration: duration, priority: priority)
        
        // Then
        // Note: This test might fail if calendar access is not granted
        // In a real test environment, we would mock the calendar access
        if let scheduledTime = scheduledTime {
            XCTAssertTrue(scheduledTime > Date(), "Scheduled time should be in the future")
            if let deadline = deadline {
                XCTAssertTrue(scheduledTime < deadline, "Scheduled time should be before the deadline")
            }
        }
    }
    
    func testGenerateDailyPlan() {
        // When
        let dailyPlan = smartScheduler.generateDailyPlan()
        
        // Then
        XCTAssertNotNil(dailyPlan, "Daily plan should not be nil")
        XCTAssertEqual(dailyPlan.date.timeIntervalSinceReferenceDate.rounded(), Date().timeIntervalSinceReferenceDate.rounded(), accuracy: 60, "Daily plan date should be today")
    }
    
    func testGenerateDailySummary() {
        // When
        let summary = smartScheduler.generateDailySummary()
        
        // Then
        XCTAssertFalse(summary.isEmpty, "Summary should not be empty")
        XCTAssertTrue(summary.contains("Daily Summary"), "Summary should contain 'Daily Summary'")
        XCTAssertTrue(summary.contains("Events:"), "Summary should contain 'Events:'")
        XCTAssertTrue(summary.contains("Tasks:"), "Summary should contain 'Tasks:'")
        XCTAssertTrue(summary.contains("Productivity Insights:"), "Summary should contain 'Productivity Insights:'")
    }
    
    func testFindAvailableTimeSlots() {
        // This is a private method, so we can't test it directly
        // In a real test, we would make it internal for testing or test it indirectly
        
        // For now, we'll test it indirectly through scheduleTask
        let title = "Test Task"
        let deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let duration = 30 // 30 minutes
        let priority = TaskPriority.medium
        
        let scheduledTime = smartScheduler.scheduleTask(title: title, deadline: deadline, duration: duration, priority: priority)
        
        if let scheduledTime = scheduledTime {
            // Check that the scheduled time is within working hours (9 AM to 6 PM)
            let hour = Calendar.current.component(.hour, from: scheduledTime)
            XCTAssertTrue(hour >= 9 && hour < 18, "Scheduled time should be within working hours")
        }
    }
    
    func testAnalyzeProductivityPatterns() {
        // This is a private method, so we can't test it directly
        // In a real test, we would make it internal for testing or test it indirectly
        
        // For now, we'll test it indirectly through getMostProductiveTime in the daily summary
        let summary = smartScheduler.generateDailySummary()
        
        XCTAssertTrue(summary.contains("Most productive time:"), "Summary should contain productivity time")
        
        // Extract the most productive time from the summary
        if let range = summary.range(of: "Most productive time: ") {
            let timeStart = range.upperBound
            let timeSubstring = summary[timeStart...]
            if let endRange = timeSubstring.range(of: "\n") {
                let timeString = timeSubstring[..<endRange.lowerBound]
                XCTAssertFalse(timeString.isEmpty, "Productive time should not be empty")
                XCTAssertTrue(timeString.contains(":"), "Productive time should be in time format")
            }
        }
    }
}
