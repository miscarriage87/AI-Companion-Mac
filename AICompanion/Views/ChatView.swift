
//
//  ChatView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI
import Markdown
import UniformTypeIdentifiers

/// Chat interface view for the application
struct ChatView: View {
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var sidebarViewModel: SidebarViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var animationManager: AnimationManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    @ObservedObject private var feedbackManager = FeedbackManager.shared
    @ObservedObject private var dragDropManager = DragDropManager.shared
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    @State private var messageText = ""
    @State private var isTyping = false
    @State private var scrollToBottom = false
    @State private var isDropTargeted = false
    @State private var showKeyboardShortcuts = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            HStack {
                Text(chatViewModel.currentConversation?.title ?? "New Chat".localized)
                    .font(.headline)
                    .accessibilityLabel("\(chatViewModel.currentConversation?.title ?? "New Chat".localized) conversation")
                
                if let provider = chatViewModel.currentProvider {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(provider.name)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Using \(provider.name) AI provider")
                }
                
                Spacer()
                
                if chatViewModel.isProcessing {
                    HStack(spacing: 8) {
                        Text("Thinking...".localized)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .padding(.trailing, 8)
                    .accessibilityLabel("AI is thinking")
                }
                
                Menu {
                    Button(action: {
                        chatViewModel.clearCurrentChat()
                        feedbackManager.performHapticFeedback(.medium)
                    }) {
                        Label("Clear Chat".localized, systemImage: "trash")
                    }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    
                    Button(action: {
                        chatViewModel.exportChat()
                        feedbackManager.performHapticFeedback(.light)
                    }) {
                        Label("Export Chat".localized, systemImage: "square.and.arrow.up")
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    
                    Divider()
                    
                    Menu("AI Provider".localized) {
                        ForEach(sidebarViewModel.aiProviders.filter(\.isEnabled)) { provider in
                            Button(action: {
                                chatViewModel.changeProvider(to: provider.id)
                                feedbackManager.performHapticFeedback(.selection)
                            }) {
                                HStack {
                                    Text(provider.name)
                                    
                                    if chatViewModel.currentConversation?.aiProviderId == provider.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        showKeyboardShortcuts = true
                    }) {
                        Label("Keyboard Shortcuts".localized, systemImage: "keyboard")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .accessibilityLabel("Chat options")
                }
                .withHapticFeedback(.light)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .animation(animationManager.animation(for: .viewTransition), value: chatViewModel.currentConversation?.title)
            
            Divider()
            
            // Empty state
            if chatViewModel.messages.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .pulseAnimation()
                    
                    Text("Start a new conversation".localized)
                        .font(.title2)
                        .fontWeight(.medium)
                        .accessibilityAdjustedFont(size: 20, weight: .medium)
                    
                    Text("Type a message below to begin chatting with your AI companion".localized)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(["Tell me about quantum computing", "Write a short story about a robot learning to paint", "Explain the concept of neural networks"], id: \.self) { suggestion in
                            Button(action: {
                                messageText = suggestion
                                sendMessage()
                                feedbackManager.performHapticFeedback(.selection)
                                feedbackManager.playSound(.click)
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.accentColor)
                                    
                                    Text(suggestion.localized)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .withHapticFeedback(.light)
                            .accessibilityLabel("Suggestion: \(suggestion)")
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestinationWithFeedback(for: URL.self, isTargeted: $isDropTargeted) { urls, _ in
                    handleDroppedFiles(urls)
                    return true
                }
                .overlay(
                    Group {
                        if isDropTargeted {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .padding()
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
                                .overlay(
                                    Text("Drop files here to upload".localized)
                                        .font(.title3)
                                        .foregroundColor(.accentColor)
                                        .padding()
                                        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
                                        .cornerRadius(8)
                                )
                        }
                    }
                )
            } else {
                // Messages list
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(chatViewModel.messages) { message in
                                MessageView(message: message, showTimestamp: settingsViewModel.showTimestamps)
                                    .id(message.id)
                                    .contextMenu {
                                        Button(action: {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(message.content, forType: .string)
                                            feedbackManager.performHapticFeedback(.light)
                                            feedbackManager.playSound(.click)
                                        }) {
                                            Label("Copy".localized, systemImage: "doc.on.doc")
                                        }
                                        
                                        Button(action: {
                                            // Share message
                                            let sharingServicePicker = NSSharingServicePicker(items: [message.content])
                                            if let window = NSApplication.shared.windows.first {
                                                sharingServicePicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
                                            }
                                            feedbackManager.performHapticFeedback(.light)
                                        }) {
                                            Label("Share".localized, systemImage: "square.and.arrow.up")
                                        }
                                        
                                        if !message.isFromUser {
                                            Divider()
                                            
                                            Button(action: {
                                                chatViewModel.regenerateLastResponse()
                                                feedbackManager.performHapticFeedback(.medium)
                                            }) {
                                                Label("Regenerate Response".localized, systemImage: "arrow.clockwise")
                                            }
                                        }
                                    }
                                    .draggableItem(message.content) {
                                        MessageDragPreview(message: message)
                                    }
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .center)).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                                        removal: .opacity.animation(.easeOut(duration: 0.2))
                                    ))
                            }
                            
                            // Typing indicator
                            if isTyping && !chatViewModel.isProcessing {
                                HStack(alignment: .top) {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("typingIndicator")
                                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatViewModel.messages) { _ in
                        if let lastMessage = chatViewModel.messages.last {
                            withAnimation(animationManager.animation(for: .viewTransition)) {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                            
                            // Play sound for new message
                            if lastMessage.isFromUser {
                                feedbackManager.playSound(.messageSent)
                            } else {
                                feedbackManager.playSound(.messageReceived)
                            }
                        }
                    }
                    .onChange(of: isTyping) { _ in
                        if isTyping {
                            withAnimation(animationManager.animation(for: .viewTransition)) {
                                scrollView.scrollTo("typingIndicator", anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastMessage = chatViewModel.messages.last {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                    .dropDestinationWithFeedback(for: URL.self, isTargeted: $isDropTargeted) { urls, _ in
                        handleDroppedFiles(urls)
                        return true
                    }
                    .overlay(
                        Group {
                            if isDropTargeted {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    .padding()
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
                                    .overlay(
                                        Text("Drop files here to upload".localized)
                                            .font(.title3)
                                            .foregroundColor(.accentColor)
                                            .padding()
                                            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
                                            .cornerRadius(8)
                                    )
                            }
                        }
                    )
                }
            }
            
            Divider()
            
            // Input area
            VStack(spacing: 8) {
                HStack(alignment: .bottom) {
                    // Text input
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $messageText)
                            .font(.body)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .frame(minHeight: 40, maxHeight: 120)
                            .focused($isInputFocused)
                            .accessibilityLabel("Message input field")
                        
                        if messageText.isEmpty {
                            Text("Type a message...".localized)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    // Send button
                    Button(action: {
                        sendMessage()
                        feedbackManager.performHapticFeedback(.light)
                        feedbackManager.playSound(.messageSent)
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatViewModel.isProcessing ? .secondary : .accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatViewModel.isProcessing)
                    .keyboardShortcut(.return, modifiers: [.command])
                    .help("Send Message (⌘+Return)".localized)
                    .accessibilityLabel("Send message")
                    .scaleEffect(messageText.isEmpty ? 1.0 : 1.05)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
                }
                
                // Input accessories
                HStack(spacing: 16) {
                    Button(action: {
                        // Show file picker
                        let openPanel = NSOpenPanel()
                        openPanel.allowsMultipleSelection = true
                        openPanel.canChooseDirectories = false
                        openPanel.canChooseFiles = true
                        openPanel.allowedContentTypes = dragDropManager.supportedDocumentTypes
                        
                        openPanel.begin { response in
                            if response == .OK {
                                handleDroppedFiles(openPanel.urls)
                            }
                        }
                        
                        feedbackManager.performHapticFeedback(.light)
                        feedbackManager.playSound(.click)
                    }) {
                        Image(systemName: "paperclip")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Attach File".localized)
                    .accessibilityLabel("Attach file")
                    .withHapticFeedback(.light)
                    
                    Button(action: {
                        // Start voice input
                        startVoiceInput()
                        feedbackManager.performHapticFeedback(.medium)
                        feedbackManager.playSound(.click)
                    }) {
                        Image(systemName: "mic")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Voice Input".localized)
                    .accessibilityLabel("Start voice input")
                    .withHapticFeedback(.light)
                    
                    Button(action: {
                        showKeyboardShortcuts = true
                        feedbackManager.performHapticFeedback(.light)
                    }) {
                        Image(systemName: "keyboard")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Keyboard Shortcuts".localized)
                    .accessibilityLabel("Show keyboard shortcuts")
                    .withHapticFeedback(.light)
                    
                    Spacer()
                    
                    if !messageText.isEmpty {
                        Text("\(messageText.count) characters".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding()
        }
        .onAppear {
            isInputFocused = true
        }
        .sheet(isPresented: $showKeyboardShortcuts) {
            KeyboardShortcutsView()
        }
        .withAccessibility()
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty && !chatViewModel.isProcessing {
            // Show typing indicator briefly
            isTyping = true
            
            // Haptic feedback
            feedbackManager.performHapticFeedback(.light)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTyping = false
                chatViewModel.sendMessage(trimmedText)
                messageText = ""
            }
        }
    }
    
    private func startVoiceInput() {
        // This would be implemented to start voice recognition
        // For now, we'll just show a placeholder message
        messageText = "Voice input activated..."
    }
    
    private func handleDroppedFiles(_ urls: [URL]) -> Bool {
        // Process dropped files
        for url in urls {
            if dragDropManager.isDocumentTypeSupported(UTType(filenameExtension: url.pathExtension) ?? .item) {
                // Add file reference to the message
                messageText += "\n[File: \(url.lastPathComponent)]"
                
                // In a real implementation, you would upload the file or process it
                // chatViewModel.uploadFile(url)
            }
        }
        
        // Provide feedback
        feedbackManager.performHapticFeedback(.medium)
        feedbackManager.playSound(.success)
        
        return true
    }
}

/// Individual message view
struct MessageView: View {
    let message: Message
    let showTimestamp: Bool
    
    @EnvironmentObject private var animationManager: AnimationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject private var feedbackManager = FeedbackManager.shared
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    @State private var isHovering = false
    @State private var isAppearing = false
    
    var body: some View {
        HStack(alignment: .bottom) {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .top) {
                    if !message.isFromUser {
                        // AI avatar
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "brain")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 16))
                        }
                        .scaleEffect(isAppearing ? 1.0 : 0.1)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .accessibilityHidden(true)
                    }
                    
                    VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                        // Message content with markdown support
                        MarkdownView(text: message.content)
                            .padding(12)
                            .background(
                                message.isFromUser 
                                ? themeManager.currentTheme.primaryColor.light.opacity(0.2) 
                                : Color(NSColor.controlBackgroundColor)
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .scaleEffect(isAppearing ? 1.0 : 0.95)
                            .opacity(isAppearing ? 1.0 : 0.0)
                        
                        // Timestamp
                        if showTimestamp {
                            HStack(spacing: 4) {
                                if message.isFromUser {
                                    if isHovering {
                                        Text("You".localized)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(formatTime(message.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(formatTime(message.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    if isHovering {
                                        Text("AI".localized)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .opacity(isAppearing ? 1.0 : 0.0)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(message.isFromUser ? "You: \(message.content)" : "AI: \(message.content)")
                    .accessibilityHint(showTimestamp ? "Sent at \(formatTime(message.timestamp))" : "")
                    
                    if message.isFromUser {
                        // User avatar
                        ZStack {
                            Circle()
                                .fill(themeManager.currentTheme.primaryColor.light.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "person.fill")
                                .foregroundColor(themeManager.currentTheme.primaryColor.light)
                                .font(.system(size: 16))
                        }
                        .scaleEffect(isAppearing ? 1.0 : 0.1)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .accessibilityHidden(true)
                    }
                }
            }
            .frame(maxWidth: 600, alignment: message.isFromUser ? .trailing : .leading)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .onTapGesture {
                feedbackManager.performHapticFeedback(.light)
            }
            .onAppear {
                let animation = animationManager.animation(for: .messageAppear)
                
                withAnimation(animation) {
                    isAppearing = true
                }
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Message drag preview
struct MessageDragPreview: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: message.isFromUser ? "person.fill" : "brain")
                    .foregroundColor(.white)
                
                Text(message.isFromUser ? "You".localized : "AI".localized)
                    .font(.caption)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
            
            Text(message.content)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(8)
        .background(Color.accentColor)
        .cornerRadius(8)
        .frame(width: 200)
    }
}

/// Typing indicator animation
struct TypingIndicator: View {
    @State private var animationOffset = 0.0
    @EnvironmentObject private var animationManager: AnimationManager
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset(for: index))
                    .animation(
                        animationManager.animation(for: .typingIndicator)?.delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .onAppear {
            animationOffset = 1.0
        }
        .accessibilityLabel("AI is typing")
    }
    
    private func animationOffset(for index: Int) -> Double {
        return animationOffset * -5.0
    }
}

/// Markdown rendering view
struct MarkdownView: View {
    let text: String
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        Text(LocalizedStringKey(text))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .font(.system(size: accessibilityManager.adjustedFontSize(14)))
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(ChatViewModel())
            .environmentObject(SidebarViewModel())
            .environmentObject(SettingsViewModel())
            .environmentObject(AnimationManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}
