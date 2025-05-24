
import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @StateObject private var viewModel = VoiceSettingsViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Voice Input")) {
                Toggle("Enable Voice Input", isOn: $viewModel.isVoiceInputEnabled)
                    .onChange(of: viewModel.isVoiceInputEnabled) { _ in
                        viewModel.saveSettings()
                    }
                
                if viewModel.isVoiceInputEnabled {
                    Toggle("Continuous Listening Mode", isOn: $viewModel.isContinuousListeningEnabled)
                        .onChange(of: viewModel.isContinuousListeningEnabled) { _ in
                            viewModel.saveSettings()
                        }
                    
                    Slider(value: $viewModel.voiceInputTimeout, in: 1...60, step: 1) {
                        Text("Voice Input Timeout")
                    } minimumValueLabel: {
                        Text("1s")
                    } maximumValueLabel: {
                        Text("60s")
                    }
                    .onChange(of: viewModel.voiceInputTimeout) { _ in
                        viewModel.saveSettings()
                    }
                    
                    Text("Voice Input Timeout: \(Int(viewModel.voiceInputTimeout)) seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Voice Output")) {
                Toggle("Enable Voice Output", isOn: $viewModel.isVoiceOutputEnabled)
                    .onChange(of: viewModel.isVoiceOutputEnabled) { _ in
                        viewModel.saveSettings()
                    }
                
                if viewModel.isVoiceOutputEnabled {
                    Toggle("Automatically Read AI Responses", isOn: $viewModel.autoReadResponses)
                        .onChange(of: viewModel.autoReadResponses) { _ in
                            viewModel.saveSettings()
                        }
                    
                    Picker("Voice", selection: $viewModel.selectedVoiceIdentifier) {
                        ForEach(viewModel.availableVoices, id: \.identifier) { voice in
                            Text(voice.name)
                                .tag(voice.identifier)
                        }
                    }
                    .onChange(of: viewModel.selectedVoiceIdentifier) { _ in
                        viewModel.saveSettings()
                    }
                    
                    Slider(value: $viewModel.speechRate, in: 0...1, step: 0.1) {
                        Text("Speech Rate")
                    } minimumValueLabel: {
                        Text("Slow")
                    } maximumValueLabel: {
                        Text("Fast")
                    }
                    .onChange(of: viewModel.speechRate) { _ in
                        viewModel.saveSettings()
                    }
                    
                    Slider(value: $viewModel.speechPitch, in: 0.5...2, step: 0.1) {
                        Text("Speech Pitch")
                    } minimumValueLabel: {
                        Text("Low")
                    } maximumValueLabel: {
                        Text("High")
                    }
                    .onChange(of: viewModel.speechPitch) { _ in
                        viewModel.saveSettings()
                    }
                    
                    Slider(value: $viewModel.speechVolume, in: 0...1, step: 0.1) {
                        Text("Speech Volume")
                    } minimumValueLabel: {
                        Text("Quiet")
                    } maximumValueLabel: {
                        Text("Loud")
                    }
                    .onChange(of: viewModel.speechVolume) { _ in
                        viewModel.saveSettings()
                    }
                    
                    Button("Test Voice") {
                        viewModel.testVoice()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section(header: Text("Voice Commands")) {
                Toggle("Enable Voice Commands", isOn: $viewModel.isVoiceCommandsEnabled)
                    .onChange(of: viewModel.isVoiceCommandsEnabled) { _ in
                        viewModel.saveSettings()
                    }
                
                if viewModel.isVoiceCommandsEnabled {
                    Text("Available Commands:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• \"Send [message]\" - Send a message")
                        Text("• \"Clear chat\" - Clear the conversation")
                        Text("• \"Stop listening\" - Stop voice input")
                        Text("• \"Read response\" - Read the last AI response")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Voice Settings")
        .onAppear {
            viewModel.loadSettings()
        }
    }
}

class VoiceSettingsViewModel: ObservableObject {
    // MARK: - Voice Input Settings
    
    @Published var isVoiceInputEnabled = true
    @Published var isContinuousListeningEnabled = false
    @Published var voiceInputTimeout: Double = 10
    
    // MARK: - Voice Output Settings
    
    @Published var isVoiceOutputEnabled = true
    @Published var autoReadResponses = false
    @Published var selectedVoiceIdentifier = ""
    @Published var speechRate: Float = 0.5
    @Published var speechPitch: Float = 1.0
    @Published var speechVolume: Float = 1.0
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    
    // MARK: - Voice Command Settings
    
    @Published var isVoiceCommandsEnabled = true
    
    // MARK: - Private Properties
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    init() {
        loadAvailableVoices()
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Load available voices for speech synthesis
    func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Set default voice if not already set
        if selectedVoiceIdentifier.isEmpty, let defaultVoice = AVSpeechSynthesisVoice(language: "en-US") {
            selectedVoiceIdentifier = defaultVoice.identifier
        }
    }
    
    /// Load settings from UserDefaults
    func loadSettings() {
        isVoiceInputEnabled = userDefaults.bool(forKey: "voice_input_enabled")
        isContinuousListeningEnabled = userDefaults.bool(forKey: "continuous_listening_enabled")
        voiceInputTimeout = userDefaults.double(forKey: "voice_input_timeout")
        
        isVoiceOutputEnabled = userDefaults.bool(forKey: "voice_output_enabled")
        autoReadResponses = userDefaults.bool(forKey: "auto_read_responses")
        
        if let voiceIdentifier = userDefaults.string(forKey: "selected_voice_identifier") {
            selectedVoiceIdentifier = voiceIdentifier
        } else if let defaultVoice = AVSpeechSynthesisVoice(language: "en-US") {
            selectedVoiceIdentifier = defaultVoice.identifier
        }
        
        speechRate = userDefaults.float(forKey: "speech_rate")
        speechPitch = userDefaults.float(forKey: "speech_pitch")
        speechVolume = userDefaults.float(forKey: "speech_volume")
        
        isVoiceCommandsEnabled = userDefaults.bool(forKey: "voice_commands_enabled")
        
        // Set default values if not already set
        if voiceInputTimeout == 0 {
            voiceInputTimeout = 10
        }
        
        if speechRate == 0 {
            speechRate = 0.5
        }
        
        if speechPitch == 0 {
            speechPitch = 1.0
        }
        
        if speechVolume == 0 {
            speechVolume = 1.0
        }
    }
    
    /// Save settings to UserDefaults
    func saveSettings() {
        userDefaults.set(isVoiceInputEnabled, forKey: "voice_input_enabled")
        userDefaults.set(isContinuousListeningEnabled, forKey: "continuous_listening_enabled")
        userDefaults.set(voiceInputTimeout, forKey: "voice_input_timeout")
        
        userDefaults.set(isVoiceOutputEnabled, forKey: "voice_output_enabled")
        userDefaults.set(autoReadResponses, forKey: "auto_read_responses")
        userDefaults.set(selectedVoiceIdentifier, forKey: "selected_voice_identifier")
        userDefaults.set(speechRate, forKey: "speech_rate")
        userDefaults.set(speechPitch, forKey: "speech_pitch")
        userDefaults.set(speechVolume, forKey: "speech_volume")
        
        userDefaults.set(isVoiceCommandsEnabled, forKey: "voice_commands_enabled")
    }
    
    /// Test the selected voice
    func testVoice() {
        let utterance = AVSpeechUtterance(string: "This is a test of the selected voice.")
        
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            utterance.voice = voice
        }
        
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    VoiceSettingsView()
}
