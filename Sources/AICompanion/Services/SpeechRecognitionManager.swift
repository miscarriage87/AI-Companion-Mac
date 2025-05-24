
import Foundation
import Speech
import AVFoundation
import Combine

/// Manager class for handling speech recognition functionality
class SpeechRecognitionManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Indicates if speech recognition is currently active
    @Published var isRecording = false
    
    /// The current transcribed text
    @Published var transcribedText = ""
    
    /// Indicates if there was an error during speech recognition
    @Published var hasError = false
    
    /// Error message if there was an error during speech recognition
    @Published var errorMessage: String?
    
    /// Indicates if speech recognition is available on the device
    @Published var isAvailable = false
    
    // MARK: - Private Properties
    
    /// The speech recognizer used for recognition
    private var speechRecognizer: SFSpeechRecognizer?
    
    /// The audio engine used for capturing audio
    private let audioEngine = AVAudioEngine()
    
    /// The current recognition request
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// The current recognition task
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Timer for continuous listening mode
    private var restartTimer: Timer?
    
    /// Indicates if continuous listening mode is enabled
    private var continuousListening = false
    
    /// The locale used for speech recognition
    private var locale: Locale = .current
    
    /// The maximum duration for a single recognition session (in seconds)
    private let maxRecognitionDuration: TimeInterval = 60
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    // MARK: - Public Methods
    
    /// Request authorization for speech recognition
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.isAvailable = true
                case .denied, .restricted, .notDetermined:
                    self?.isAvailable = false
                    self?.hasError = true
                    self?.errorMessage = "Speech recognition authorization was not granted."
                @unknown default:
                    self?.isAvailable = false
                    self?.hasError = true
                    self?.errorMessage = "Unknown authorization status for speech recognition."
                }
            }
        }
    }
    
    /// Set the locale for speech recognition
    /// - Parameter locale: The locale to use for speech recognition
    func setLocale(_ locale: Locale) {
        self.locale = locale
        setupSpeechRecognizer()
    }
    
    /// Start speech recognition
    /// - Parameter continuous: Whether to use continuous listening mode
    func startRecording(continuous: Bool = false) {
        // Check if we're already recording
        if isRecording {
            stopRecording()
        }
        
        // Set continuous listening mode
        continuousListening = continuous
        
        // Reset state
        transcribedText = ""
        hasError = false
        errorMessage = nil
        
        // Check if speech recognition is available
        guard isAvailable else {
            hasError = true
            errorMessage = "Speech recognition is not available on this device."
            return
        }
        
        // Check if the speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            hasError = true
            errorMessage = "Speech recognizer is not available right now."
            return
        }
        
        // Configure audio session
        do {
            try configureAudioSession()
        } catch {
            hasError = true
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Check if the recognition request was created
        guard let recognitionRequest = recognitionRequest else {
            hasError = true
            errorMessage = "Failed to create speech recognition request."
            return
        }
        
        // Configure recognition request
        recognitionRequest.shouldReportPartialResults = true
        
        // Create recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Update transcribed text
                self.transcribedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            // Handle errors or completion
            if error != nil || isFinal {
                // Stop audio engine
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                // Reset recognition task and request
                self.recognitionTask = nil
                self.recognitionRequest = nil
                
                // If continuous listening is enabled, restart recognition
                if self.continuousListening && self.isRecording {
                    self.restartRecognition()
                } else {
                    DispatchQueue.main.async {
                        self.isRecording = false
                    }
                }
            }
        }
        
        // Configure audio engine
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            
            // If continuous listening is enabled, set up timer to restart recognition
            if continuous {
                restartTimer = Timer.scheduledTimer(withTimeInterval: maxRecognitionDuration, repeats: false) { [weak self] _ in
                    self?.restartRecognition()
                }
            }
        } catch {
            hasError = true
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            isRecording = false
        }
    }
    
    /// Stop speech recognition
    func stopRecording() {
        // Cancel restart timer
        restartTimer?.invalidate()
        restartTimer = nil
        
        // Stop continuous listening
        continuousListening = false
        
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End recognition request
        recognitionRequest?.endAudio()
        
        // Cancel recognition task
        recognitionTask?.cancel()
        
        // Reset state
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    // MARK: - Private Methods
    
    /// Set up the speech recognizer with the current locale
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        speechRecognizer?.delegate = self
        requestAuthorization()
    }
    
    /// Configure the audio session for speech recognition
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    /// Restart speech recognition for continuous listening mode
    private func restartRecognition() {
        // Stop current recognition
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Start new recognition session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.isRecording else { return }
            
            // Create new recognition request
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = self.recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            // Create new recognition task
            self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                var isFinal = false
                
                if let result = result {
                    // Update transcribed text
                    self.transcribedText = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                
                // Handle errors or completion
                if error != nil || isFinal {
                    // Stop audio engine
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    
                    // Reset recognition task and request
                    self.recognitionTask = nil
                    self.recognitionRequest = nil
                    
                    // If continuous listening is enabled, restart recognition
                    if self.continuousListening && self.isRecording {
                        self.restartRecognition()
                    } else {
                        DispatchQueue.main.async {
                            self.isRecording = false
                        }
                    }
                }
            }
            
            // Configure audio engine
            let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
            self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            // Start audio engine
            do {
                self.audioEngine.prepare()
                try self.audioEngine.start()
                
                // Reset timer for continuous listening
                self.restartTimer?.invalidate()
                self.restartTimer = Timer.scheduledTimer(withTimeInterval: self.maxRecognitionDuration, repeats: false) { [weak self] _ in
                    self?.restartRecognition()
                }
            } catch {
                self.hasError = true
                self.errorMessage = "Failed to restart audio engine: \(error.localizedDescription)"
                self.isRecording = false
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognitionManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.isAvailable = available
            
            if !available {
                self.hasError = true
                self.errorMessage = "Speech recognition is not available right now."
                self.isRecording = false
            }
        }
    }
}
