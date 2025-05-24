//
//  MultiModalManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import Vision
import AVFoundation
import CoreML
import SwiftUI
import Speech
import NaturalLanguage

/// Manager for handling multi-modal interactions (images, audio)
class MultiModalManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = MultiModalManager()
    
    /// AI service for interacting with AI providers
    private let aiService: AIService
    
    /// Audio session for recording and playback
    private let audioSession = AVAudioSession.sharedInstance()
    
    /// Speech recognizer for converting speech to text
    private let speechRecognizer = SpeechRecognizer()
    
    /// Speech synthesizer for converting text to speech
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    /// Image analyzer for processing images
    private let imageAnalyzer = ImageAnalyzer()
    
    /// Background task manager for multi-modal operations
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    /// Whether speech recognition is available
    @Published var isSpeechRecognitionAvailable: Bool = false
    
    /// Whether speech synthesis is available
    @Published var isSpeechSynthesisAvailable: Bool = true
    
    /// Whether image analysis is available
    @Published var isImageAnalysisAvailable: Bool = false
    
    /// Whether audio recording is in progress
    @Published var isRecording: Bool = false
    
    /// Whether audio playback is in progress
    @Published var isPlaying: Bool = false
    
    /// Error message if something goes wrong
    @Published var errorMessage: String?
    
    /// Whether to show the error alert
    @Published var showError: Bool = false
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(aiService: AIService = AIService()) {
        self.aiService = aiService
        
        // Set up audio session
        setupAudioSession()
        
        // Check availability of speech recognition
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isSpeechRecognitionAvailable = status == .authorized
            }
        }
        
        // Check availability of image analysis
        checkImageAnalysisAvailability()
        
        // Set up observers
        setupObservers()
    }
    
    /// Set up the audio session for recording and playback
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Check if image analysis is available
    private func checkImageAnalysisAvailability() {
        // Check if Vision framework is available
        if #available(macOS 10.15, *) {
            isImageAnalysisAvailable = true
        } else {
            isImageAnalysisAvailable = false
        }
    }
    
    /// Set up observers for notifications
    private func setupObservers() {
        // Observe speech recognizer status
        speechRecognizer.$isAvailable
            .sink { [weak self] isAvailable in
                self?.isSpeechRecognitionAvailable = isAvailable
            }
            .store(in: &cancellables)
        
        // Observe speech recognizer recording status
        speechRecognizer.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
        
        // Observe speech recognizer errors
        speechRecognizer.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                self?.showError = true
            }
            .store(in: &cancellables)
        
        // Observe image analyzer status
        imageAnalyzer.$isAnalyzing
            .sink { [weak self] isAnalyzing in
                // Handle analyzing status changes
            }
            .store(in: &cancellables)
        
        // Observe image analyzer errors
        imageAnalyzer.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                self?.showError = true
            }
            .store(in: &cancellables)
        
        // Observe speech synthesizer status
        NotificationCenter.default.publisher(for: AVSpeechSynthesizer.didStartSpeechUtteranceNotification)
            .sink { [weak self] _ in
                self?.isPlaying = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: AVSpeechSynthesizer.didFinishSpeechUtteranceNotification)
            .sink { [weak self] _ in
                self?.isPlaying = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Speech Recognition
    
    /// Start speech recognition
    func startSpeechRecognition() async throws -> AsyncThrowingStream<String, Error> {
        return try await speechRecognizer.startRecognition()
    }
    
    /// Stop speech recognition
    func stopSpeechRecognition() {
        speechRecognizer.stopRecognition()
    }
    
    // MARK: - Speech Synthesis
    
    /// Speak text
    func speak(_ text: String, voice: String? = nil, rate: Float = 0.5, pitch: Float = 1.0, volume: Float = 1.0) {
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Set voice
        if let voiceIdentifier = voice {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Set properties
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        
        // Speak
        speechSynthesizer.speak(utterance)
    }
    
    /// Stop speaking
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    /// Get available voices
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }
    
    // MARK: - Image Analysis
    
    /// Analyze an image
    func analyzeImage(_ image: NSImage) async throws -> ImageAnalysisResult {
        return try await imageAnalyzer.analyzeImage(image)
    }
    
    /// Generate a caption for an image
    func generateImageCaption(_ image: NSImage) async throws -> String {
        // First, analyze the image
        let analysisResult = try await imageAnalyzer.analyzeImage(image)
        
        // Then, use the AI service to generate a caption
        let prompt = """
        Generate a detailed caption for an image with the following elements:
        
        Objects: \(analysisResult.objects.joined(separator: ", "))
        Scenes: \(analysisResult.scenes.joined(separator: ", "))
        Faces: \(analysisResult.faceCount) faces detected
        Text: \(analysisResult.text)
        
        The caption should be concise but descriptive.
        """
        
        // Get the default AI provider
        let provider = aiService.getDefaultProvider()
        
        // Create a message for the AI
        let message = Message(
            content: prompt,
            isFromUser: true
        )
        
        // Generate a response
        let response = try await aiService.generateResponse(messages: [message], provider: provider)
        
        return response
    }
    
    // MARK: - Audio Recording
    
    /// Record audio
    func recordAudio(duration: TimeInterval? = nil) async throws -> URL {
        // Create a temporary file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // Set up audio recorder
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder.prepareToRecord()
        
        // Start recording
        audioRecorder.record()
        isRecording = true
        
        // If duration is specified, stop after that time
        if let duration = duration {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            audioRecorder.stop()
            isRecording = false
            return audioFilename
        }
        
        // Otherwise, return a continuation that will be resumed when stopRecording is called
        return try await withCheckedThrowingContinuation { continuation in
            // Store the continuation for later use
            self.backgroundTaskManager.executeTask {
                // Wait for recording to stop
                while self.isRecording {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                
                continuation.resume(returning: audioFilename)
                return true
            }
        }
    }
    
    /// Stop audio recording
    func stopAudioRecording() {
        isRecording = false
    }
    
    // MARK: - Audio Playback
    
    /// Play audio from a URL
    func playAudio(from url: URL) throws {
        // Set up audio player
        let audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer.prepareToPlay()
        
        // Play audio
        audioPlayer.play()
        isPlaying = true
        
        // Set up notification for when playback finishes
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }
    }
    
    /// Stop audio playback
    func stopAudioPlayback() {
        // This would stop the AVAudioPlayer
        // In a real implementation, we would store a reference to the player
        isPlaying = false
    }
    
    // MARK: - Multi-modal Message Creation
    
    /// Create a multi-modal message with text and image
    func createMultiModalMessage(text: String, image: NSImage) -> MultiModalMessage {
        return MultiModalMessage(text: text, images: [image])
    }
    
    /// Create a multi-modal message with text and audio
    func createMultiModalMessage(text: String, audioURL: URL) -> MultiModalMessage {
        return MultiModalMessage(text: text, audioURLs: [audioURL])
    }
    
    /// Create a multi-modal message with text, image, and audio
    func createMultiModalMessage(text: String, image: NSImage, audioURL: URL) -> MultiModalMessage {
        return MultiModalMessage(text: text, images: [image], audioURLs: [audioURL])
    }
}

/// Speech recognizer for converting speech to text
class SpeechRecognizer: ObservableObject {
    /// Whether speech recognition is available
    @Published var isAvailable = false
    
    /// Whether speech recognition is in progress
    @Published var isRecording = false
    
    /// Recognized text
    @Published var recognizedText = ""
    
    /// Error message if something goes wrong
    @Published var errorMessage: String?
    
    /// Speech recognizer
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    /// Audio engine for recording
    private let audioEngine = AVAudioEngine()
    
    /// Current recognition task
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Current recognition request
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Current recognition continuation
    private var recognitionContinuation: AsyncThrowingStream<String, Error>.Continuation?
    
    init() {
        // Check authorization status
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAvailable = status == .authorized
            }
        }
    }
    
    /// Start speech recognition
    func startRecognition() async throws -> AsyncThrowingStream<String, Error> {
        // Check if speech recognition is available
        guard isAvailable else {
            throw SpeechRecognitionError.notAuthorized
        }
        
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }
        
        // Cancel any ongoing recognition task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Create a new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Configure the request
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create an audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Configure the audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install a tap on the audio engine
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Update state
        isRecording = true
        recognizedText = ""
        
        // Create a stream for the recognition results
        return AsyncThrowingStream<String, Error> { continuation in
            self.recognitionContinuation = continuation
            
            // Start the recognition task
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    // Handle error
                    self.errorMessage = error.localizedDescription
                    continuation.finish(throwing: error)
                    self.stopRecognition()
                    return
                }
                
                if let result = result {
                    // Update recognized text
                    self.recognizedText = result.bestTranscription.formattedString
                    
                    // Send the result to the continuation
                    continuation.yield(self.recognizedText)
                    
                    // If final result, finish the continuation
                    if result.isFinal {
                        continuation.finish()
                        self.stopRecognition()
                    }
                }
            }
        }
    }
    
    /// Stop speech recognition
    func stopRecognition() {
        // Stop the audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Cancel the recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // End the recognition request
        recognitionRequest = nil
        
        // Update state
        isRecording = false
        
        // Finish the continuation
        recognitionContinuation?.finish()
        recognitionContinuation = nil
    }
    
    /// Errors that can occur with speech recognition
    enum SpeechRecognitionError: Error, LocalizedError {
        case notAuthorized
        case recognizerNotAvailable
        case requestCreationFailed
        case audioEngineFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Speech recognition is not authorized"
            case .recognizerNotAvailable:
                return "Speech recognizer is not available"
            case .requestCreationFailed:
                return "Failed to create speech recognition request"
            case .audioEngineFailed:
                return "Audio engine failed to start"
            }
        }
    }
}

/// Image analyzer for processing images
class ImageAnalyzer: ObservableObject {
    /// Whether image analysis is in progress
    @Published var isAnalyzing = false
    
    /// Analysis results
    @Published var analysisResults: [ImageAnalysisResult] = []
    
    /// Error message if something goes wrong
    @Published var errorMessage: String?
    
    /// Analyze an image
    func analyzeImage(_ image: NSImage) async throws -> ImageAnalysisResult {
        // Update state
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        // Convert NSImage to CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageAnalysisError.imageConversionFailed
        }
        
        // Create a Vision image
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create requests
        let objectRecognitionRequest = VNRecognizeObjectsRequest()
        let textRecognitionRequest = VNRecognizeTextRequest()
        let faceDetectionRequest = VNDetectFaceRectanglesRequest()
        let sceneClassificationRequest = VNClassifyImageRequest()
        
        // Configure requests
        objectRecognitionRequest.revision = VNRecognizeObjectsRequestRevision1
        textRecognitionRequest.revision = VNRecognizeTextRequestRevision2
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        
        // Perform requests
        try imageRequestHandler.perform([
            objectRecognitionRequest,
            textRecognitionRequest,
            faceDetectionRequest,
            sceneClassificationRequest
        ])
        
        // Process object recognition results
        let objectObservations = objectRecognitionRequest.results as? [VNRecognizedObjectObservation] ?? []
        let objects = objectObservations.compactMap { observation -> String? in
            guard let label = observation.labels.first?.identifier else { return nil }
            return label
        }
        
        // Process text recognition results
        let textObservations = textRecognitionRequest.results as? [VNRecognizedTextObservation] ?? []
        let texts = textObservations.compactMap { observation -> String? in
            return observation.topCandidates(1).first?.string
        }
        let text = texts.joined(separator: " ")
        
        // Process face detection results
        let faceObservations = faceDetectionRequest.results as? [VNFaceObservation] ?? []
        let faceCount = faceObservations.count
        
        // Process scene classification results
        let sceneObservations = sceneClassificationRequest.results as? [VNClassificationObservation] ?? []
        let scenes = sceneObservations
            .filter { $0.confidence > 0.5 }
            .compactMap { $0.identifier }
        
        // Create result
        let result = ImageAnalysisResult(
            objects: objects,
            text: text,
            faceCount: faceCount,
            scenes: scenes
        )
        
        // Update state
        DispatchQueue.main.async {
            self.isAnalyzing = false
            self.analysisResults.append(result)
        }
        
        return result
    }
    
    /// Errors that can occur with image analysis
    enum ImageAnalysisError: Error, LocalizedError {
        case imageConversionFailed
        case requestFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image"
            case .requestFailed(let message):
                return "Image analysis request failed: \(message)"
            }
        }
    }
}

/// Result of image analysis
struct ImageAnalysisResult: Identifiable {
    /// Unique identifier for the result
    let id = UUID()
    
    /// Objects detected in the image
    let objects: [String]
    
    /// Text detected in the image
    let text: String
    
    /// Number of faces detected in the image
    let faceCount: Int
    
    /// Scenes detected in the image
    let scenes: [String]
    
    /// Timestamp when the analysis was performed
    let timestamp = Date()
}

/// Multi-modal message with text, images, and audio
struct MultiModalMessage: Identifiable {
    /// Unique identifier for the message
    let id = UUID()
    
    /// Text content of the message
    let text: String
    
    /// Images included in the message
    let images: [NSImage]
    
    /// Audio URLs included in the message
    let audioURLs: [URL]
    
    /// Timestamp when the message was created
    let timestamp = Date()
    
    init(text: String, images: [NSImage] = [], audioURLs: [URL] = []) {
        self.text = text
        self.images = images
        self.audioURLs = audioURLs
    }
}
