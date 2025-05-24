
//
//  CollaborationManagerTests.swift
//  AI CompanionTests
//
//  Created: May 20, 2025
//

import XCTest
@testable import AI_Companion

class CollaborationManagerTests: XCTestCase {
    
    var collaborationManager: CollaborationManager!
    
    override func setUp() {
        super.setUp()
        collaborationManager = CollaborationManager()
    }
    
    override func tearDown() {
        collaborationManager = nil
        super.tearDown()
    }
    
    func testCreateSession() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Test User")
        
        // When
        let session = collaborationManager.createSession(name: sessionName, creator: creator)
        
        // Then
        XCTAssertEqual(session.name, sessionName, "Session name should match")
        XCTAssertEqual(session.createdBy, creator.id, "Creator ID should match")
        XCTAssertEqual(session.status, .active, "Session should be active")
    }
    
    func testJoinSession() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Creator")
        let joiner = createUser(name: "Joiner")
        
        // Create a session
        let session = collaborationManager.createSession(name: sessionName, creator: creator)
        
        // When
        let joinResult = collaborationManager.joinSession(sessionID: session.id, user: joiner)
        
        // Then
        XCTAssertTrue(joinResult, "Join should succeed")
        
        // Check connected users
        let connectedUsers = collaborationManager.getConnectedUsers()
        XCTAssertEqual(connectedUsers.count, 2, "Should have 2 connected users")
        XCTAssertTrue(connectedUsers.contains { $0.id == creator.id }, "Creator should be connected")
        XCTAssertTrue(connectedUsers.contains { $0.id == joiner.id }, "Joiner should be connected")
    }
    
    func testLeaveSession() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Creator")
        let joiner = createUser(name: "Joiner")
        
        // Create a session and join
        let session = collaborationManager.createSession(name: sessionName, creator: creator)
        collaborationManager.joinSession(sessionID: session.id, user: joiner)
        
        // When
        collaborationManager.leaveSession(user: joiner)
        
        // Then
        let connectedUsers = collaborationManager.getConnectedUsers()
        XCTAssertEqual(connectedUsers.count, 1, "Should have 1 connected user")
        XCTAssertTrue(connectedUsers.contains { $0.id == creator.id }, "Creator should still be connected")
        XCTAssertFalse(connectedUsers.contains { $0.id == joiner.id }, "Joiner should not be connected")
    }
    
    func testCreateSharedDocument() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Creator")
        let documentTitle = "Test Document"
        let documentContent = "This is a test document"
        
        // Create a session
        collaborationManager.createSession(name: sessionName, creator: creator)
        
        // When
        let document = collaborationManager.createSharedDocument(title: documentTitle, content: documentContent, creator: creator)
        
        // Then
        XCTAssertEqual(document.title, documentTitle, "Document title should match")
        XCTAssertEqual(document.createdBy, creator.id, "Creator ID should match")
        
        // Check document content
        let content = collaborationManager.getDocumentContent(documentID: document.id)
        XCTAssertEqual(content, documentContent, "Document content should match")
    }
    
    func testShareDocument() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Creator")
        let collaborator = createUser(name: "Collaborator")
        let documentTitle = "Test Document"
        let documentContent = "This is a test document"
        
        // Create a session and join
        collaborationManager.createSession(name: sessionName, creator: creator)
        collaborationManager.joinSession(sessionID: collaborationManager.createSession(name: sessionName, creator: creator).id, user: collaborator)
        
        // Create a document
        let document = collaborationManager.createSharedDocument(title: documentTitle, content: documentContent, creator: creator)
        
        // When
        let shareResult = collaborationManager.shareDocument(documentID: document.id, userID: collaborator.id, role: .editor)
        
        // Then
        XCTAssertTrue(shareResult, "Share should succeed")
        
        // Check access
        let hasAccess = collaborationManager.hasDocumentAccess(userID: collaborator.id, documentID: document.id, requiredRole: .editor)
        XCTAssertTrue(hasAccess, "Collaborator should have editor access")
    }
    
    func testApplyEdit() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Creator")
        let documentTitle = "Test Document"
        let documentContent = "This is a test document"
        
        // Create a session
        collaborationManager.createSession(name: sessionName, creator: creator)
        
        // Create a document
        let document = collaborationManager.createSharedDocument(title: documentTitle, content: documentContent, creator: creator)
        
        // Create an edit operation
        let operation = EditOperation(
            type: .insert,
            position: documentContent.count,
            content: " with an edit",
            timestamp: Date(),
            userID: creator.id
        )
        
        // When
        let editResult = collaborationManager.applyEdit(documentID: document.id, userID: creator.id, operation: operation)
        
        // Then
        XCTAssertTrue(editResult, "Edit should succeed")
        
        // Check updated content
        let updatedContent = collaborationManager.getDocumentContent(documentID: document.id)
        XCTAssertEqual(updatedContent, "This is a test document with an edit", "Document content should be updated")
        
        // Check document version
        let updatedDocument = collaborationManager.getSharedDocument(documentID: document.id)
        XCTAssertEqual(updatedDocument?.version, 2, "Document version should be incremented")
    }
    
    func testAddAnnotation() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Creator")
        let documentTitle = "Test Document"
        let documentContent = "This is a test document"
        
        // Create a session
        collaborationManager.createSession(name: sessionName, creator: creator)
        
        // Create a document
        let document = collaborationManager.createSharedDocument(title: documentTitle, content: documentContent, creator: creator)
        
        // Create an annotation
        let annotation = DocumentAnnotation(
            id: UUID(),
            userID: creator.id,
            createdAt: Date(),
            type: .comment,
            position: 5,
            content: "This is a comment",
            replies: []
        )
        
        // When
        let annotationResult = collaborationManager.addAnnotation(documentID: document.id, userID: creator.id, annotation: annotation)
        
        // Then
        XCTAssertTrue(annotationResult, "Annotation should succeed")
        
        // Check annotations
        let annotations = collaborationManager.getAnnotations(documentID: document.id)
        XCTAssertEqual(annotations.count, 1, "Should have 1 annotation")
        XCTAssertEqual(annotations[0].content, "This is a comment", "Annotation content should match")
    }
    
    func testShareConversation() {
        // Given
        let sessionName = "Test Session"
        let creator = createUser(name: "Creator")
        
        // Create a session
        collaborationManager.createSession(name: sessionName, creator: creator)
        
        // Create a conversation
        let conversation = SharedConversation(
            id: UUID(),
            title: "Test Conversation",
            createdAt: Date(),
            createdBy: creator.id,
            messages: [
                SharedMessage(
                    id: UUID(),
                    userID: creator.id,
                    timestamp: Date(),
                    content: "Hello",
                    isAI: false
                ),
                SharedMessage(
                    id: UUID(),
                    userID: UUID(),
                    timestamp: Date(),
                    content: "Hi there!",
                    isAI: true
                )
            ]
        )
        
        // When
        let shareResult = collaborationManager.shareConversation(conversation, userID: creator.id)
        
        // Then
        XCTAssertTrue(shareResult, "Share should succeed")
    }
    
    // MARK: - Helper Methods
    
    private func createUser(name: String) -> CollaborationUser {
        return CollaborationUser(
            id: UUID(),
            name: name,
            email: "\(name.lowercased())@example.com",
            avatarURL: nil
        )
    }
}
