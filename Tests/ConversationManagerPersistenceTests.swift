import XCTest
@testable import AI_Companion

class ConversationManagerPersistenceTests: XCTestCase {
    func testConversationPersistence() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = ConversationManager(directory: tempDir)
        let conversation = manager.createNewConversation(title: "Persisted")
        manager.addMessage(Message(role: .user, content: "Hello"))
        manager.addMessage(Message(role: .assistant, content: "Hi"))

        // Recreate manager to simulate app restart
        let manager2 = ConversationManager(directory: tempDir)
        XCTAssertEqual(manager2.conversations.count, manager.conversations.count)
        let reloaded = manager2.conversations.first { $0.id == conversation.id }
        XCTAssertEqual(reloaded?.messages.count, conversation.messages.count)
    }

    func testSummaryPersistence() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = ConversationManager(directory: tempDir)
        let conversation = manager.currentConversation
        let summary = ConversationSummary(conversationId: conversation.id, content: "Summary", summarizedMessageIds: [])
        manager.saveSummary(summary)

        let manager2 = ConversationManager(directory: tempDir)
        let loadedSummaries = manager2.summaries[conversation.id] ?? []
        XCTAssertEqual(loadedSummaries.count, 1)
        XCTAssertEqual(loadedSummaries.first?.content, "Summary")
    }
}
