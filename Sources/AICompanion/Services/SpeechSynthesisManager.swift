
import Foundation
import AVFoundation
import Combine

/// Manager class for handling speech synthesis functionality
class SpeechSynthesisManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    // MARK: - Published Properties
    
    /// Indicates if speech synthesis is currently active
    @Published var isSpeaking = false
    
    /// Indicates if speech synthesis is paused
    @Published var isPaused = false
    
    /// The current voice being used for speech synthesis
    @Published var currentVoice: AVSpeechSynthesisVoice?
    
    /// Available voices for speech synthesis
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    
    /// The speech rate (0.0 - 1.0)
    @Published var rate: Float = 0.5
    
    /// The speech pitch (0.5 - 2.0)
    @Published var pitch: Float = 1.0
    
    /// The speech volume (0.0 - 1.0)
    @Published var volume: Float = 1.0
    
    // MARK: - Private Properties
    
    /// The speech synthesizer used for synthesis
    private let synthesizer = AVSpeechSynthesizer()
    
    /// Queue for managing multiple speech requests
    private var speechQueue: [AVSpeechUtterance] = []
    
    /// Indicates if the synthesizer is currently processing the queue
    private var isProcessingQueue = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        synthesizer.delegate = self
        loadAvailableVoices()
        setDefaultVoice()
    }
    
    // MARK: - Public Methods
    
    /// Speak the provided text
    /// - Parameters:
    ///   - text: The text to speak
    ///   - voice: The voice to use (optional)
    ///   - rate: The speech rate (optional)
    ///   - pitch: The speech pitch (optional)
    ///   - volume: The speech volume (optional)
    ///   - immediate: Whether to speak immediately or add to queue
    func speak(_ text: String, voice: AVSpeechSynthesisVoice? = nil, rate: Float? = nil, pitch: Float? = nil, volume: Float? = nil, immediate: Bool = false) {
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure utterance
        utterance.voice = voice ?? currentVoice
        utterance.rate = rate ?? self.rate
        utterance.pitchMultiplier = pitch ?? self.pitch
        utterance.volume = volume ?? self.volume
        
        // Speak immediately or add to queue
        if immediate {
            // Stop current speech and clear queue
            synthesizer.stopSpeaking(at: .immediate)
            speechQueue.removeAll()
            
            // Speak immediately
            synthesizer.speak(utterance)
        } else {
            // Add to queue
            speechQueue.append(utterance)
            
            // Process queue if not already processing
            if !isProcessingQueue {
                processQueue()
            }
        }
    }
    
    /// Speak multiple texts sequentially
    /// - Parameters:
    ///   - texts: The texts to speak
    ///   - voice: The voice to use (optional)
    ///   - rate: The speech rate (optional)
    ///   - pitch: The speech pitch (optional)
    ///   - volume: The speech volume (optional)
    ///   - immediate: Whether to speak immediately or add to queue
    func speakMultiple(_ texts: [String], voice: AVSpeechSynthesisVoice? = nil, rate: Float? = nil, pitch: Float? = nil, volume: Float? = nil, immediate: Bool = false) {
        // Create utterances
        let utterances = texts.map { text -> AVSpeechUtterance in
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = voice ?? currentVoice
            utterance.rate = rate ?? self.rate
            utterance.pitchMultiplier = pitch ?? self.pitch
            utterance.volume = volume ?? self.volume
            return utterance
        }
        
        // Speak immediately or add to queue
        if immediate {
            // Stop current speech and clear queue
            synthesizer.stopSpeaking(at: .immediate)
            speechQueue.removeAll()
            
            // Add utterances to queue
            speechQueue.append(contentsOf: utterances)
            
            // Process queue
            processQueue()
        } else {
            // Add utterances to queue
            speechQueue.append(contentsOf: utterances)
            
            // Process queue if not already processing
            if !isProcessingQueue {
                processQueue()
            }
        }
    }
    
    /// Stop speaking
    /// - Parameter boundary: The boundary at which to stop speaking
    func stopSpeaking(at boundary: AVSpeechBoundary = .immediate) {
        synthesizer.stopSpeaking(at: boundary)
        speechQueue.removeAll()
        isProcessingQueue = false
    }
    
    /// Pause speaking
    /// - Parameter boundary: The boundary at which to pause speaking
    func pauseSpeaking(at boundary: AVSpeechBoundary = .word) {
        synthesizer.pauseSpeaking(at: boundary)
    }
    
    /// Continue speaking
    func continueSpeaking() {
        synthesizer.continueSpeaking()
    }
    
    /// Set the voice for speech synthesis
    /// - Parameter voice: The voice to use
    func setVoice(_ voice: AVSpeechSynthesisVoice) {
        currentVoice = voice
    }
    
    /// Set the voice for speech synthesis by identifier
    /// - Parameter identifier: The identifier of the voice to use
    func setVoice(identifier: String) {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            currentVoice = voice
        }
    }
    
    /// Set the voice for speech synthesis by language
    /// - Parameter language: The language code of the voice to use
    func setVoice(language: String) {
        if let voice = AVSpeechSynthesisVoice(language: language) {
            currentVoice = voice
        }
    }
    
    // MARK: - Private Methods
    
    /// Load available voices for speech synthesis
    private func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
    }
    
    /// Set the default voice for speech synthesis
    private func setDefaultVoice() {
        // Try to get system voice
        let systemVoice = AVSpeechSynthesisVoice.currentLanguageCode()
        if let voice = AVSpeechSynthesisVoice(language: systemVoice) {
            currentVoice = voice
        } else {
            // Fallback to English
            currentVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
    }
    
    /// Process the speech queue
    private func processQueue() {
        // Check if already processing or queue is empty
        guard !isProcessingQueue, !speechQueue.isEmpty else {
            return
        }
        
        // Set processing flag
        isProcessingQueue = true
        
        // Get next utterance
        let utterance = speechQueue.removeFirst()
        
        // Speak utterance
        synthesizer.speak(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Process next utterance in queue if available
            if !self.speechQueue.isEmpty {
                self.processQueue()
            } else {
                // No more utterances in queue
                self.isSpeaking = false
                self.isPaused = false
                self.isProcessingQueue = false
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Process next utterance in queue if available
            if !self.speechQueue.isEmpty {
                self.processQueue()
            } else {
                // No more utterances in queue
                self.isSpeaking = false
                self.isPaused = false
                self.isProcessingQueue = false
            }
        }
    }
}
