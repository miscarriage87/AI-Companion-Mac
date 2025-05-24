
//
//  SidebarView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// Sidebar navigation view for the application
struct SidebarView: View {
    @EnvironmentObject private var sidebarViewModel: SidebarViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var documentManager: DocumentManager
    
    @State private var searchText = ""
    @State private var showRenameDialog = false
    @State private var conversationToRename: Conversation?
    @State private var newConversationTitle = ""
    @State private var showAddTagSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search conversations", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding([.horizontal, .top], 8)
            
            // New chat button
            Button(action: {
                chatViewModel.startNewChat()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("New Chat")
                        .fontWeight(.medium)
                    Spacer()
                    Text("⌘N")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            Divider()
                .padding(.vertical, 8)
            
            // Conversations list
            List(selection: $sidebarViewModel.selectedConversationId) {
                Section(header: Text("Recent Conversations")) {
                    ForEach(filteredConversations) { conversation in
                        ConversationRow(conversation: conversation)
                            .tag(conversation.id)
                            .contextMenu {
                                Button(action: {
                                    conversationToRename = conversation
                                    newConversationTitle = conversation.title
                                    showRenameDialog = true
                                }) {
                                    Label("Rename", systemImage: "pencil")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    sidebarViewModel.deleteConversation(conversation)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                    }
                }
                
                // Document section
                documentSection
                
                Section(header: Text("AI Providers")) {
                    ForEach(sidebarViewModel.aiProviders) { provider in
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(provider.isEnabled ? .accentColor : .secondary)
                            
                            VStack(alignment: .leading) {
                                Text(provider.name)
                                    .fontWeight(provider.isEnabled ? .medium : .regular)
                                
                                Text(provider.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if provider.isEnabled {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sidebarViewModel.selectAIProvider(provider)
                        }
                    }
                    
                    Button(action: {
                        settingsViewModel.showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Manage Providers")
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(SidebarListStyle())
        }
        .alert("Rename Conversation", isPresented: $showRenameDialog) {
            TextField("Conversation Title", text: $newConversationTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Cancel", role: .cancel) {
                showRenameDialog = false
            }
            
            Button("Rename") {
                if let conversation = conversationToRename {
                    sidebarViewModel.renameConversation(conversation, newTitle: newConversationTitle)
                }
                showRenameDialog = false
            }
        }
    }
    
    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return sidebarViewModel.conversations
        } else {
            return sidebarViewModel.conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // AI Provider icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 18))
            }
            
            // Conversation details
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let lastMessage = conversation.messages.last {
                    Text(lastMessage.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Timestamp
            VStack(alignment: .trailing) {
                Text(formatDate(conversation.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(conversation.messages.count) msgs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(SidebarViewModel())
            .environmentObject(ChatViewModel())
            .environmentObject(SettingsViewModel())
    }
}
