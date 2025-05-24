
//
//  TaskPrioritizerTests.swift
//  AI CompanionTests
//
//  Created: May 20, 2025
//

import XCTest
@testable import AI_Companion

class TaskPrioritizerTests: XCTestCase {
    
    var userPreferencesManager: UserPreferencesManager!
    var contextManager: ContextManager!
    var taskPrioritizer: TaskPrioritizer!
    
    override func setUp() {
        super.setUp()
        userPreferencesManager = UserPreferencesManager()
        contextManager = ContextManager()
        taskPrioritizer = TaskPrioritizer(userPreferencesManager: userPreferencesManager, contextManager: contextManager)
    }
    
    override func tearDown() {
        taskPrioritizer = nil
        contextManager = nil
        userPreferencesManager = nil
        super.tearDown()
    }
    
    func testPrioritizeTasks() {
        // Given
        let tasks = [
            createTask(title: "Urgent Task", deadline: Date().addingTimeInterval(3600), importance: .high),
            createTask(title: "Regular Task", deadline: Date().addingTimeInterval(86400), importance: .medium),
            createTask(title: "Low Priority Task", deadline: Date().addingTimeInterval(172800), importance: .low)
        ]
        
        // When
        let prioritizedTasks = taskPrioritizer.prioritizeTasks(tasks)
        
        // Then
        XCTAssertEqual(prioritizedTasks.count, 3, "Should have 3 prioritized tasks")
        XCTAssertEqual(prioritizedTasks[0].task.title, "Urgent Task", "Urgent task should be first")
        XCTAssertEqual(prioritizedTasks[1].task.title, "Regular Task", "Regular task should be second")
        XCTAssertEqual(prioritizedTasks[2].task.title, "Low Priority Task", "Low priority task should be last")
        
        // Check that scores are in descending order
        XCTAssertGreaterThan(prioritizedTasks[0].priorityScore, prioritizedTasks[1].priorityScore, "First task should have higher score than second")
        XCTAssertGreaterThan(prioritizedTasks[1].priorityScore, prioritizedTasks[2].priorityScore, "Second task should have higher score than third")
    }
    
    func testGetRecommendedTasks() {
        // Given
        let tasks = [
            createTask(title: "Urgent Task", deadline: Date().addingTimeInterval(3600), importance: .high),
            createTask(title: "Regular Task", deadline: Date().addingTimeInterval(86400), importance: .medium),
            createTask(title: "Low Priority Task", deadline: Date().addingTimeInterval(172800), importance: .low),
            createTask(title: "Another Task", deadline: Date().addingTimeInterval(259200), importance: .medium)
        ]
        
        // When
        let recommendations = taskPrioritizer.getRecommendedTasks(from: tasks)
        
        // Then
        XCTAssertEqual(recommendations.count, 3, "Should have 3 recommended tasks")
        XCTAssertEqual(recommendations[0].task.title, "Urgent Task", "Urgent task should be first recommendation")
        
        // Check that each recommendation has a reason
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.reason.isEmpty, "Recommendation should have a reason")
        }
    }
    
    func testLearnFromUserFeedback() {
        // Given
        let task = createTask(title: "Test Task", deadline: Date().addingTimeInterval(86400), importance: .medium)
        let userPriority = 90.0
        let modelPriority = 70.0
        
        // When
        taskPrioritizer.learnFromUserFeedback(task: task, userPriority: userPriority, modelPriority: modelPriority)
        
        // Then
        // This is mostly a behavioral test, so we're just checking that it doesn't crash
        // In a real test, we would verify that the user preferences were updated
        let categories = userPreferencesManager.getPreferredTaskCategories()
        XCTAssertTrue(categories.contains(where: { $0.contains("work") }), "Work category should be preferred")
    }
    
    // MARK: - Helper Methods
    
    private func createTask(title: String, deadline: Date?, importance: TaskImportance) -> Task {
        return Task(
            id: UUID(),
            title: title,
            description: "Test task description",
            deadline: deadline,
            importance: importance,
            estimatedDuration: 60, // 60 minutes
            category: .work,
            preferredLocation: .work,
            blocksOtherTasks: []
        )
    }
}
