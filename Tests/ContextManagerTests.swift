
//
//  ContextManagerTests.swift
//  AI CompanionTests
//
//  Created: May 20, 2025
//

import XCTest
import CoreLocation
@testable import AI_Companion

class ContextManagerTests: XCTestCase {
    
    var contextManager: ContextManager!
    
    override func setUp() {
        super.setUp()
        contextManager = ContextManager()
    }
    
    override func tearDown() {
        contextManager = nil
        super.tearDown()
    }
    
    func testGetCurrentLocation() {
        // When
        let location = contextManager.getCurrentLocation()
        
        // Then
        // Since we can't control the actual location in a test environment,
        // we'll just check that the method returns a valid location type
        XCTAssertNotNil(location, "Location should not be nil")
    }
    
    func testGetCurrentActivity() {
        // When
        let activity = contextManager.getCurrentActivity()
        
        // Then
        // Since we can't control the actual activity in a test environment,
        // we'll just check that the method returns a valid activity
        XCTAssertNotNil(activity, "Activity should not be nil")
    }
    
    func testGetCurrentTimeContext() {
        // When
        let timeContext = contextManager.getCurrentTimeContext()
        
        // Then
        XCTAssertNotNil(timeContext, "Time context should not be nil")
        XCTAssertEqual(timeContext.date.timeIntervalSinceReferenceDate.rounded(), Date().timeIntervalSinceReferenceDate.rounded(), accuracy: 60, "Time context date should be now")
        
        // Check time of day
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 {
            XCTAssertEqual(timeContext.timeOfDay, .morning, "Time of day should be morning")
        } else if hour >= 12 && hour < 17 {
            XCTAssertEqual(timeContext.timeOfDay, .afternoon, "Time of day should be afternoon")
        } else if hour >= 17 && hour < 21 {
            XCTAssertEqual(timeContext.timeOfDay, .evening, "Time of day should be evening")
        } else {
            XCTAssertEqual(timeContext.timeOfDay, .night, "Time of day should be night")
        }
        
        // Check day type
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 {
            XCTAssertEqual(timeContext.dayType, .weekend, "Day type should be weekend")
        } else {
            XCTAssertEqual(timeContext.dayType, .weekday, "Day type should be weekday")
        }
    }
    
    func testGetCurrentCalendarContext() {
        // When
        let calendarContext = contextManager.getCurrentCalendarContext()
        
        // Then
        XCTAssertNotNil(calendarContext, "Calendar context should not be nil")
        
        // Since we can't control the actual calendar in a test environment,
        // we'll just check that the method returns a valid context
        // In a real test, we would mock the calendar access
    }
    
    func testGetCurrentContext() {
        // When
        let context = contextManager.getCurrentContext()
        
        // Then
        XCTAssertNotNil(context, "Context should not be nil")
        XCTAssertEqual(context.timestamp.timeIntervalSinceReferenceDate.rounded(), Date().timeIntervalSinceReferenceDate.rounded(), accuracy: 60, "Context timestamp should be now")
        XCTAssertNotNil(context.location, "Context location should not be nil")
        XCTAssertNotNil(context.activity, "Context activity should not be nil")
        XCTAssertNotNil(context.timeContext, "Context time context should not be nil")
        XCTAssertNotNil(context.calendarContext, "Context calendar context should not be nil")
        XCTAssertNotNil(context.systemContext, "Context system context should not be nil")
    }
    
    func testGenerateProactiveSuggestions() {
        // When
        let suggestions = contextManager.generateProactiveSuggestions()
        
        // Then
        XCTAssertFalse(suggestions.isEmpty, "Should generate at least one suggestion")
        
        // Check that suggestions are sorted by priority
        for i in 0..<(suggestions.count - 1) {
            XCTAssertGreaterThanOrEqual(suggestions[i].priority.rawValue, suggestions[i + 1].priority.rawValue, "Suggestions should be sorted by priority")
        }
        
        // Check suggestion properties
        for suggestion in suggestions {
            XCTAssertFalse(suggestion.title.isEmpty, "Suggestion title should not be empty")
            XCTAssertFalse(suggestion.description.isEmpty, "Suggestion description should not be empty")
        }
    }
}
