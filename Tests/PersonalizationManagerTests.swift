
//
//  PersonalizationManagerTests.swift
//  AI CompanionTests
//
//  Created: May 20, 2025
//

import XCTest
@testable import AI_Companion

class PersonalizationManagerTests: XCTestCase {
    
    var userPreferencesManager: UserPreferencesManager!
    var userBehaviorAnalyzer: UserBehaviorAnalyzer!
    var personalizationManager: PersonalizationManager!
    
    override func setUp() {
        super.setUp()
        userPreferencesManager = UserPreferencesManager()
        userBehaviorAnalyzer = UserBehaviorAnalyzer(userPreferencesManager: userPreferencesManager)
        personalizationManager = PersonalizationManager(userPreferencesManager: userPreferencesManager, userBehaviorAnalyzer: userBehaviorAnalyzer)
    }
    
    override func tearDown() {
        personalizationManager = nil
        userBehaviorAnalyzer = nil
        userPreferencesManager = nil
        super.tearDown()
    }
    
    func testPersonalizeResponse() {
        // Given
        let content = "This is a test response"
        let context = ResponseContext.factualQuestion
        
        // When
        let personalizedResponse = personalizationManager.personalizeResponse(content: content, context: context)
        
        // Then
        XCTAssertFalse(personalizedResponse.isEmpty, "Personalized response should not be empty")
        XCTAssertTrue(personalizedResponse.contains(content), "Personalized response should contain the original content")
    }
    
    func testPersonalizeResponseWithGreeting() {
        // Given
        let content = "How can I help you today?"
        let context = ResponseContext.greeting
        
        // When
        let personalizedResponse = personalizationManager.personalizeResponse(content: content, context: context)
        
        // Then
        XCTAssertFalse(personalizedResponse.isEmpty, "Personalized response should not be empty")
        XCTAssertTrue(personalizedResponse.contains(content), "Personalized response should contain the original content")
        
        // Check for greeting
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        if timeOfDay >= 5 && timeOfDay < 12 {
            XCTAssertTrue(personalizedResponse.contains("Good morning"), "Greeting should contain 'Good morning'")
        } else if timeOfDay >= 12 && timeOfDay < 18 {
            XCTAssertTrue(personalizedResponse.contains("Good afternoon"), "Greeting should contain 'Good afternoon'")
        } else {
            XCTAssertTrue(personalizedResponse.contains("Good evening"), "Greeting should contain 'Good evening'")
        }
    }
    
    func testGetPersonalizedUISettings() {
        // When
        let settings = personalizationManager.getPersonalizedUISettings()
        
        // Then
        XCTAssertFalse(settings.isEmpty, "UI settings should not be empty")
        XCTAssertNotNil(settings["colorScheme"], "UI settings should include color scheme")
        XCTAssertNotNil(settings["fontSize"], "UI settings should include font size")
        XCTAssertNotNil(settings["layout"], "UI settings should include layout")
        XCTAssertNotNil(settings["featuredItems"], "UI settings should include featured items")
    }
    
    func testGetPersonalizedDashboardItems() {
        // When
        let items = personalizationManager.getPersonalizedDashboardItems()
        
        // Then
        XCTAssertFalse(items.isEmpty, "Dashboard items should not be empty")
        
        // Check that items are sorted by priority
        for i in 0..<(items.count - 1) {
            XCTAssertLessThanOrEqual(items[i].priority, items[i + 1].priority, "Items should be sorted by priority")
        }
    }
    
    func testLearnFromFeedback() {
        // Given
        let feedback = PersonalizationFeedback(
            style: .technical,
            styleRating: 5,
            uiRating: 4,
            colorScheme: "dark",
            fontSize: "large",
            layout: "compact",
            comments: "I prefer technical responses and a compact layout"
        )
        
        // When
        personalizationManager.learnFromFeedback(feedback)
        
        // Then
        // Check that preferences were updated
        XCTAssertEqual(userPreferencesManager.getPreferredResponseStyle(), .technical, "Response style should be updated to technical")
        XCTAssertEqual(userPreferencesManager.getPreferredColorScheme(), "dark", "Color scheme should be updated to dark")
        XCTAssertEqual(userPreferencesManager.getPreferredFontSize(), "large", "Font size should be updated to large")
        XCTAssertEqual(userPreferencesManager.getPreferredLayout(), "compact", "Layout should be updated to compact")
    }
}
