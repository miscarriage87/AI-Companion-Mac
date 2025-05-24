
//
//  CollaborationManager.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine

/// CollaborationManager enables team collaboration features
/// It manages shared conversations, documents, and collaborative editing
class CollaborationManager {
    // MARK: - Properties
    
    // Collaboration session
    private var activeSession: CollaborationSession?
    private var connectedUsers: [CollaborationUser] = []
    
    // Document management
    private var sharedDocuments: [UUID: SharedDocument] = [:]
    
    // Access control
    private var accessControlList: [UUID: [UUID: AccessRole]] = [:] // [DocumentID: [UserID: Role]]
    
    // CRDT for collaborative editing
    private var documentCRDTs: [UUID: DocumentCRDT] = [:]
    
    // Publishers
    private let sessionUpdateSubject = PassthroughSubject<SessionUpdate, Never>()
    private let documentUpdateSubject = PassthroughSubject<DocumentUpdate, Never>()
    
    var sessionUpdates: AnyPublisher<SessionUpdate, Never> {
        return sessionUpdateSubject.eraseToAnyPublisher()
    }
    
    var documentUpdates: AnyPublisher<DocumentUpdate, Never> {
        return documentUpdateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize with no active session
    }
    
    // MARK: - Session Management
    
    /// Create a new collaboration session
    /// - Parameters:
    ///   - name: Session name
    ///   - creator: User creating the session
    /// - Returns: The created session
    func createSession(name: String, creator: CollaborationUser) -> CollaborationSession {
        // Create a new session
        let session = CollaborationSession(
            id: UUID(),
            name: name,
            createdAt: Date(),
            createdBy: creator.id,
            status: .active
        )
        
        // Set as active session
        activeSession = session
        
        // Add creator as first connected user
        connectedUsers = [creator]
        
        // Notify subscribers
        sessionUpdateSubject.send(SessionUpdate(
            type: .sessionCreated,
            sessionID: session.id,
            data: ["name": name, "creator": creator.name]
        ))
        
        return session
    }
    
    /// Join an existing collaboration session
    /// - Parameters:
    ///   - sessionID: ID of the session to join
    ///   - user: User joining the session
    /// - Returns: Success status
    func joinSession(sessionID: UUID, user: CollaborationUser) -> Bool {
        // In a real implementation, this would connect to a remote session
        // For now, we'll simulate joining the active session
        
        guard let session = activeSession, session.id == sessionID else {
            return false
        }
        
        // Check if user is already connected
        if connectedUsers.contains(where: { $0.id == user.id }) {
            return true
        }
        
        // Add user to connected users
        connectedUsers.append(user)
        
        // Notify subscribers
        sessionUpdateSubject.send(SessionUpdate(
            type: .userJoined,
            sessionID: sessionID,
            data: ["user": user.name]
        ))
        
        return true
    }
    
    /// Leave the current collaboration session
    /// - Parameter user: User leaving the session
    func leaveSession(user: CollaborationUser) {
        guard let session = activeSession else {
            return
        }
        
        // Remove user from connected users
        connectedUsers.removeAll { $0.id == user.id }
        
        // Notify subscribers
        sessionUpdateSubject.send(SessionUpdate(
            type: .userLeft,
            sessionID: session.id,
            data: ["user": user.name]
        ))
        
        // If no users left, close the session
        if connectedUsers.isEmpty {
            closeSession()
        }
    }
    
    /// Close the current collaboration session
    private func closeSession() {
        guard let session = activeSession else {
            return
        }
        
        // Update session status
        activeSession?.status = .closed
        
        // Notify subscribers
        sessionUpdateSubject.send(SessionUpdate(
            type: .sessionClosed,
            sessionID: session.id,
            data: [:]
        ))
        
        // Clear session data
        activeSession = nil
        connectedUsers = []
    }
    
    /// Get all users in the current session
    /// - Returns: Array of connected users
    func getConnectedUsers() -> [CollaborationUser] {
        return connectedUsers
    }
    
    // MARK: - Document Sharing
    
    /// Create a new shared document
    /// - Parameters:
    ///   - title: Document title
    ///   - content: Initial document content
    ///   - creator: User creating the document
    /// - Returns: The created document
    func createSharedDocument(title: String, content: String, creator: CollaborationUser) -> SharedDocument {
        guard activeSession != nil else {
            fatalError("No active session")
        }
        
        // Create a new document
        let documentID = UUID()
        let document = SharedDocument(
            id: documentID,
            title: title,
            createdAt: Date(),
            createdBy: creator.id,
            lastModifiedAt: Date(),
            lastModifiedBy: creator.id,
            version: 1
        )
        
        // Store the document
        sharedDocuments[documentID] = document
        
        // Initialize CRDT for the document
        let crdt = DocumentCRDT(documentID: documentID, initialContent: content)
        documentCRDTs[documentID] = crdt
        
        // Set creator as owner
        accessControlList[documentID] = [creator.id: .owner]
        
        // Notify subscribers
        documentUpdateSubject.send(DocumentUpdate(
            type: .documentCreated,
            documentID: documentID,
            userID: creator.id,
            data: ["title": title, "creator": creator.name]
        ))
        
        return document
    }
    
    /// Share a document with a user
    /// - Parameters:
    ///   - documentID: ID of the document to share
    ///   - userID: ID of the user to share with
    ///   - role: Access role for the user
    /// - Returns: Success status
    func shareDocument(documentID: UUID, userID: UUID, role: AccessRole) -> Bool {
        guard let document = sharedDocuments[documentID],
              var documentACL = accessControlList[documentID] else {
            return false
        }
        
        // Add user to document ACL
        documentACL[userID] = role
        accessControlList[documentID] = documentACL
        
        // Find user name
        let userName = connectedUsers.first { $0.id == userID }?.name ?? "Unknown User"
        
        // Notify subscribers
        documentUpdateSubject.send(DocumentUpdate(
            type: .documentShared,
            documentID: documentID,
            userID: userID,
            data: ["title": document.title, "user": userName, "role": role.rawValue]
        ))
        
        return true
    }
    
    /// Get all shared documents
    /// - Returns: Dictionary of document ID to document
    func getSharedDocuments() -> [UUID: SharedDocument] {
        return sharedDocuments
    }
    
    /// Get a specific shared document
    /// - Parameter documentID: ID of the document to get
    /// - Returns: The document if found
    func getSharedDocument(documentID: UUID) -> SharedDocument? {
        return sharedDocuments[documentID]
    }
    
    /// Get the content of a shared document
    /// - Parameter documentID: ID of the document
    /// - Returns: Document content if found
    func getDocumentContent(documentID: UUID) -> String? {
        return documentCRDTs[documentID]?.getContent()
    }
    
    /// Check if a user has access to a document
    /// - Parameters:
    ///   - userID: ID of the user
    ///   - documentID: ID of the document
    ///   - requiredRole: Minimum required role
    /// - Returns: Whether the user has the required access
    func hasDocumentAccess(userID: UUID, documentID: UUID, requiredRole: AccessRole) -> Bool {
        guard let documentACL = accessControlList[documentID],
              let userRole = documentACL[userID] else {
            return false
        }
        
        // Check if user's role is sufficient
        switch (userRole, requiredRole) {
        case (.owner, _):
            // Owner has all access
            return true
        case (.editor, .viewer), (.editor, .editor):
            // Editor has editor and viewer access
            return true
        case (.viewer, .viewer):
            // Viewer has only viewer access
            return true
        default:
            return false
        }
    }
    
    // MARK: - Collaborative Editing
    
    /// Apply an edit to a shared document
    /// - Parameters:
    ///   - documentID: ID of the document to edit
    ///   - userID: ID of the user making the edit
    ///   - operation: The edit operation
    /// - Returns: Success status
    func applyEdit(documentID: UUID, userID: UUID, operation: EditOperation) -> Bool {
        guard let document = sharedDocuments[documentID],
              let crdt = documentCRDTs[documentID] else {
            return false
        }
        
        // Check if user has edit access
        if !hasDocumentAccess(userID: userID, documentID: documentID, requiredRole: .editor) {
            return false
        }
        
        // Apply the edit to the CRDT
        crdt.applyOperation(operation)
        
        // Update document metadata
        var updatedDocument = document
        updatedDocument.lastModifiedAt = Date()
        updatedDocument.lastModifiedBy = userID
        updatedDocument.version += 1
        sharedDocuments[documentID] = updatedDocument
        
        // Find user name
        let userName = connectedUsers.first { $0.id == userID }?.name ?? "Unknown User"
        
        // Notify subscribers
        documentUpdateSubject.send(DocumentUpdate(
            type: .documentEdited,
            documentID: documentID,
            userID: userID,
            data: [
                "title": document.title,
                "user": userName,
                "operation": operation.description,
                "version": updatedDocument.version
            ]
        ))
        
        return true
    }
    
    /// Get the edit history for a document
    /// - Parameter documentID: ID of the document
    /// - Returns: Array of edit operations
    func getEditHistory(documentID: UUID) -> [EditHistoryItem] {
        guard let crdt = documentCRDTs[documentID] else {
            return []
        }
        
        return crdt.getHistory()
    }
    
    // MARK: - Annotations
    
    /// Add an annotation to a document
    /// - Parameters:
    ///   - documentID: ID of the document
    ///   - userID: ID of the user adding the annotation
    ///   - annotation: The annotation to add
    /// - Returns: Success status
    func addAnnotation(documentID: UUID, userID: UUID, annotation: DocumentAnnotation) -> Bool {
        guard let document = sharedDocuments[documentID],
              let crdt = documentCRDTs[documentID] else {
            return false
        }
        
        // Check if user has at least viewer access
        if !hasDocumentAccess(userID: userID, documentID: documentID, requiredRole: .viewer) {
            return false
        }
        
        // Add the annotation to the CRDT
        crdt.addAnnotation(annotation)
        
        // Find user name
        let userName = connectedUsers.first { $0.id == userID }?.name ?? "Unknown User"
        
        // Notify subscribers
        documentUpdateSubject.send(DocumentUpdate(
            type: .annotationAdded,
            documentID: documentID,
            userID: userID,
            data: [
                "title": document.title,
                "user": userName,
                "annotationType": annotation.type.rawValue,
                "position": annotation.position
            ]
        ))
        
        return true
    }
    
    /// Get all annotations for a document
    /// - Parameter documentID: ID of the document
    /// - Returns: Array of annotations
    func getAnnotations(documentID: UUID) -> [DocumentAnnotation] {
        guard let crdt = documentCRDTs[documentID] else {
            return []
        }
        
        return crdt.getAnnotations()
    }
    
    // MARK: - Conversation Sharing
    
    /// Share a conversation in the collaboration session
    /// - Parameters:
    ///   - conversation: The conversation to share
    ///   - userID: ID of the user sharing the conversation
    /// - Returns: Success status
    func shareConversation(_ conversation: SharedConversation, userID: UUID) -> Bool {
        guard activeSession != nil else {
            return false
        }
        
        // Find user name
        let userName = connectedUsers.first { $0.id == userID }?.name ?? "Unknown User"
        
        // Notify subscribers
        sessionUpdateSubject.send(SessionUpdate(
            type: .conversationShared,
            sessionID: activeSession!.id,
            data: [
                "title": conversation.title,
                "user": userName,
                "messageCount": conversation.messages.count
            ]
        ))
        
        return true
    }
}

// MARK: - Supporting Types

/// Collaboration session status
enum SessionStatus {
    case active
    case closed
}

/// Collaboration session
struct CollaborationSession {
    let id: UUID
    let name: String
    let createdAt: Date
    let createdBy: UUID
    var status: SessionStatus
}

/// Collaboration user
struct CollaborationUser {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?
}

/// Access roles for shared documents
enum AccessRole: String {
    case viewer
    case editor
    case owner
}

/// Shared document
struct SharedDocument {
    let id: UUID
    var title: String
    let createdAt: Date
    let createdBy: UUID
    var lastModifiedAt: Date
    var lastModifiedBy: UUID
    var version: Int
}

/// Types of document annotations
enum AnnotationType: String {
    case comment
    case highlight
    case suggestion
    case drawing
}

/// Document annotation
struct DocumentAnnotation {
    let id: UUID
    let userID: UUID
    let createdAt: Date
    let type: AnnotationType
    let position: Int
    let content: String
    var replies: [AnnotationReply]
}

/// Reply to an annotation
struct AnnotationReply {
    let id: UUID
    let userID: UUID
    let createdAt: Date
    let content: String
}

/// Edit operation types
enum EditOperationType {
    case insert
    case delete
    case replace
}

/// Edit operation
struct EditOperation {
    let type: EditOperationType
    let position: Int
    let content: String
    let timestamp: Date
    let userID: UUID
    
    var description: String {
        switch type {
        case .insert:
            return "Inserted \"\(content)\" at position \(position)"
        case .delete:
            return "Deleted \"\(content)\" at position \(position)"
        case .replace:
            return "Replaced with \"\(content)\" at position \(position)"
        }
    }
}

/// Edit history item
struct EditHistoryItem {
    let operation: EditOperation
    let userName: String
}

/// Shared conversation
struct SharedConversation {
    let id: UUID
    let title: String
    let createdAt: Date
    let createdBy: UUID
    let messages: [SharedMessage]
}

/// Shared message
struct SharedMessage {
    let id: UUID
    let userID: UUID
    let timestamp: Date
    let content: String
    let isAI: Bool
}

/// Session update types
enum SessionUpdateType {
    case sessionCreated
    case userJoined
    case userLeft
    case sessionClosed
    case conversationShared
}

/// Document update types
enum DocumentUpdateType {
    case documentCreated
    case documentShared
    case documentEdited
    case annotationAdded
}

/// Session update
struct SessionUpdate {
    let type: SessionUpdateType
    let sessionID: UUID
    let data: [String: Any]
}

/// Document update
struct DocumentUpdate {
    let type: DocumentUpdateType
    let documentID: UUID
    let userID: UUID
    let data: [String: Any]
}

/// CRDT for collaborative document editing
class DocumentCRDT {
    private let documentID: UUID
    private var content: String
    private var operations: [EditOperation] = []
    private var annotations: [DocumentAnnotation] = []
    
    init(documentID: UUID, initialContent: String) {
        self.documentID = documentID
        self.content = initialContent
    }
    
    func applyOperation(_ operation: EditOperation) {
        // Apply the operation to the content
        switch operation.type {
        case .insert:
            let index = min(operation.position, content.count)
            let startIndex = content.index(content.startIndex, offsetBy: index)
            content.insert(contentsOf: operation.content, at: startIndex)
            
        case .delete:
            let startIndex = content.index(content.startIndex, offsetBy: operation.position)
            let endIndex = content.index(startIndex, offsetBy: operation.content.count)
            content.removeSubrange(startIndex..<endIndex)
            
        case .replace:
            let startIndex = content.index(content.startIndex, offsetBy: operation.position)
            let endIndex = content.index(startIndex, offsetBy: operation.content.count)
            content.replaceSubrange(startIndex..<endIndex, with: operation.content)
        }
        
        // Store the operation
        operations.append(operation)
    }
    
    func addAnnotation(_ annotation: DocumentAnnotation) {
        annotations.append(annotation)
    }
    
    func getContent() -> String {
        return content
    }
    
    func getHistory() -> [EditHistoryItem] {
        // In a real implementation, this would include user names
        return operations.map { EditHistoryItem(operation: $0, userName: "Unknown User") }
    }
    
    func getAnnotations() -> [DocumentAnnotation] {
        return annotations
    }
}
