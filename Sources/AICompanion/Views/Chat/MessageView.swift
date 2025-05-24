import SwiftUI

struct MessageView: View {
    let message: Message
    @State private var showActions = false
    @EnvironmentObject var viewModel: ChatViewModel
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .leading : .trailing) {
                HStack {
                    if message.role == .assistant {
                        Text("AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if message.role == .user {
                        Text("You")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                MessageBubble(message: message)
                    .onTapGesture {
                        showActions.toggle()
                    }
                
                if showActions {
                    HStack {
                        Button(action: {
                            copyToClipboard(message.content)
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        
                        if message.role == .assistant {
                            Button(action: {
                                viewModel.regenerateResponse()
                            }) {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: 300, alignment: message.role == .user ? .leading : .trailing)
            
            if message.role == .user {
                Spacer()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

struct MessageBubble: View {
    let message: Message
    @State private var isExpanded = false
    
    var body: some View {
        Group {
            // Use MarkdownView for both user and assistant messages
            MarkdownView(content: message.content)
                .padding()
                .background(message.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(16)
                .onTapGesture {
                    if message.content.count > 500 {
                        isExpanded.toggle()
                    }
                }
                .frame(maxHeight: !isExpanded && message.content.count > 500 ? 300 : nil)
                .overlay(
                    showExpandButton ? expandButton : nil,
                    alignment: .bottomTrailing
                )
        }
    }
    
    private var showExpandButton: Bool {
        message.content.count > 500
    }
    
    private var expandButton: some View {
        Button(action: {
            isExpanded.toggle()
        }) {
            Text(isExpanded ? "Show less" : "Show more")
                .font(.caption)
                .padding(6)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
                .cornerRadius(8)
                .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(8)
    }
}

#Preview {
    MessageView(message: Message(role: .user, content: "Hello, AI!"))
        .environmentObject(ChatViewModel())
}
