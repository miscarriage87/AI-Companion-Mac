
import SwiftUI
import AVFoundation

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    @StateObject private var speechSynthesisManager = SpeechSynthesisManager()
    @StateObject private var voiceCommandManager = VoiceCommandManager()
    
    @State private var scrollToBottom = false
    @State private var isListening = false
    @State private var showVoiceInputIndicator = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader
            
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                                .environmentObject(viewModel)
                                .contextMenu {
                                    if message.role == .assistant && viewModel.isVoiceOutputEnabled {
                                        Button {
                                            speakMessage(message)
                                        } label: {
                                            Label("Read Aloud", systemImage: "speaker.wave.2")
                                        }
                                    }
                                }
                        }
                        
                        // Invisible view at the bottom for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomID")
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom = true
                    
                    // Auto-read last AI response if enabled
                    if viewModel.autoReadResponses, 
                       let lastMessage = viewModel.messages.last,
                       lastMessage.role == .assistant {
                        speakMessage(lastMessage)
                    }
                }
                .onChange(of: scrollToBottom) { newValue in
                    if newValue {
                        withAnimation {
                            scrollView.scrollTo("bottomID", anchor: .bottom)
                        }
                        scrollToBottom = false
                    }
                }
            }
            
            // Voice input indicator
            if showVoiceInputIndicator {
                VStack {
                    HStack {
                        Text(speechRecognitionManager.transcribedText.isEmpty ? "Listening..." : speechRecognitionManager.transcribedText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        // Animated microphone icon
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .opacity(isListening ? 1.0 : 0.5)
                            .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: isListening)
                            .onAppear {
                                isListening.toggle()
                            }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            
            // Input area
            chatInputArea
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Request speech recognition authorization
            speechRecognitionManager.requestAuthorization()
            
            // Load voice settings
            viewModel.loadVoiceSettings()
            
            // Configure speech synthesis
            if let voiceIdentifier = viewModel.selectedVoiceIdentifier,
               !voiceIdentifier.isEmpty {
                speechSynthesisManager.setVoice(identifier: voiceIdentifier)
            }
            
            speechSynthesisManager.rate = viewModel.speechRate
            speechSynthesisManager.pitch = viewModel.speechPitch
            speechSynthesisManager.volume = viewModel.speechVolume
            
            // Register voice commands
            registerVoiceCommands()
        }
        .onChange(of: speechRecognitionManager.transcribedText) { newValue in
            if !newValue.isEmpty {
                // Process voice commands
                if viewModel.isVoiceCommandsEnabled {
                    let commandDetected = voiceCommandManager.processText(newValue)
                    
                    if commandDetected, let command = voiceCommandManager.detectedCommand {
                        executeVoiceCommand(command, parameters: voiceCommandManager.commandParameters)
                    }
                }
            }
        }
    }
    
    // MARK: - Chat Header
    
    private var chatHeader: some View {
        HStack {
            // Model selector
            Picker("Model", selection: $viewModel.selectedModel) {
                ForEach(viewModel.availableModels) { model in
                    Text(model.name)
                        .tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 150)
            
            Spacer()
            
            // Temperature slider
            HStack {
                Text("Temperature:")
                    .font(.caption)
                Slider(value: $viewModel.temperature, in: 0...1)
                    .frame(width: 100)
                Text(String(format: "%.1f", viewModel.temperature))
                    .font(.caption)
                    .frame(width: 30)
            }
            
            // Streaming toggle
            Toggle("Streaming", isOn: $viewModel.useStreaming)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
            
            Text("Streaming")
                .font(.caption)
            
            Spacer()
            
            // Token usage indicator
            HStack {
                Text("Tokens: \(viewModel.currentConversationTokenCount) / \(viewModel.currentModelTokenLimit)")
                    .font(.caption)
                    .foregroundColor(viewModel.conversationNeedsSummarization ? .orange : .secondary)
                
                if viewModel.conversationNeedsSummarization {
                    Button(action: {
                        Task {
                            await viewModel.summarizeConversation()
                        }
                    }) {
                        Label("Summarize", systemImage: "text.append")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // New conversation button
            Button(action: viewModel.newConversation) {
                Label("New", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            
            // Clear conversation button
            Button(action: viewModel.clearConversation) {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).shadow(radius: 2))
    }
    
    // MARK: - Chat Input Area
    
    private var chatInputArea: some View {
        VStack {
            HStack(alignment: .bottom) {
                // Text input field
                TextField("Type a message...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)
                    .disabled(viewModel.isGenerating || speechRecognitionManager.isRecording)
                    .onSubmit {
                        if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isGenerating {
                            viewModel.sendMessage()
                        }
                    }
                
                // Voice input button
                if viewModel.isVoiceInputEnabled {
                    Button(action: toggleVoiceInput) {
                        Image(systemName: speechRecognitionManager.isRecording ? "mic.fill" : "mic")
                            .resizable()
                            .frame(width: 20, height: 25)
                            .foregroundColor(speechRecognitionManager.isRecording ? .red : .accentColor)
                    }
                    .disabled(viewModel.isGenerating || !speechRecognitionManager.isAvailable)
                    .keyboardShortcut("m", modifiers: [.command])
                    .help("Start/Stop Voice Input (⌘M)")
                }
                
                // Send button
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.accentColor)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Send Message (⌘Return)")
            }
            .padding()
            
            // Typing indicator
            if viewModel.isGenerating {
                HStack {
                    Text("AI is typing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(NSColor.windowBackgroundColor).shadow(radius: 2))
    }
    
    // MARK: - Voice Methods
    
    /// Toggle voice input
    private func toggleVoiceInput() {
        if speechRecognitionManager.isRecording {
            // Stop recording
            speechRecognitionManager.stopRecording()
            showVoiceInputIndicator = false
            
            // Process transcribed text if not empty
            if !speechRecognitionManager.transcribedText.isEmpty {
                // Check if it's a voice command
                if !voiceCommandManager.commandDetected {
                    // Not a command, send as message
                    viewModel.inputText = speechRecognitionManager.transcribedText
                    viewModel.sendMessage()
                }
            }
        } else {
            // Start recording
            speechRecognitionManager.startRecording(continuous: viewModel.isContinuousListeningEnabled)
            showVoiceInputIndicator = true
        }
    }
    
    /// Speak a message
    /// - Parameter message: The message to speak
    private func speakMessage(_ message: Message) {
        guard viewModel.isVoiceOutputEnabled else { return }
        
        // Configure speech synthesis
        speechSynthesisManager.rate = viewModel.speechRate
        speechSynthesisManager.pitch = viewModel.speechPitch
        speechSynthesisManager.volume = viewModel.speechVolume
        
        // Speak message
        speechSynthesisManager.speak(message.content)
    }
    
    /// Register voice commands
    private func registerVoiceCommands() {
        // Register custom commands
        let sendCommand = VoiceCommand(
            id: "send_message",
            patterns: [
                "send (.*)",
                "send message (.*)",
                "send this (.*)"
            ],
            execute: { parameters, context in
                if let messageContent = parameters["param1"] {
                    viewModel.inputText = messageContent
                    viewModel.sendMessage()
                    return true
                }
                return false
            }
        )
        
        let clearCommand = VoiceCommand(
            id: "clear_chat",
            patterns: [
                "clear chat",
                "clear conversation",
                "clear messages",
                "start new chat",
                "start new conversation"
            ],
            execute: { _, _ in
                viewModel.clearConversation()
                return true
            }
        )
        
        let stopListeningCommand = VoiceCommand(
            id: "stop_listening",
            patterns: [
                "stop listening",
                "stop recording",
                "stop voice input"
            ],
            execute: { _, _ in
                if speechRecognitionManager.isRecording {
                    speechRecognitionManager.stopRecording()
                    showVoiceInputIndicator = false
                }
                return true
            }
        )
        
        let readResponseCommand = VoiceCommand(
            id: "read_response",
            patterns: [
                "read response",
                "read message",
                "read last message",
                "read last response"
            ],
            execute: { _, _ in
                if let lastMessage = viewModel.messages.last, lastMessage.role == .assistant {
                    speakMessage(lastMessage)
                    return true
                }
                return false
            }
        )
        
        voiceCommandManager.registerCommands([
            sendCommand,
            clearCommand,
            stopListeningCommand,
            readResponseCommand
        ])
    }
    
    /// Execute a voice command
    /// - Parameters:
    ///   - command: The command to execute
    ///   - parameters: The command parameters
    private func executeVoiceCommand(_ command: VoiceCommand, parameters: [String: String]) {
        // Execute command
        let success = command.execute(parameters, self)
        
        // Provide feedback
        if success {
            // Play success sound
            NSSound.beep()
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}
