//
//  AuthService.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import SwiftUI
import Supabase
import KeychainAccess

/// Authentication state enum
enum AuthState: Equatable {
    case initializing
    case loading
    case signedIn
    case signedOut
    case confirmationRequired
    case magicLinkSent
    case passwordRecovery
    case error(Error)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.loading, .loading),
             (.signedIn, .signedIn),
             (.signedOut, .signedOut),
             (.confirmationRequired, .confirmationRequired),
             (.magicLinkSent, .magicLinkSent),
             (.passwordRecovery, .passwordRecovery):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Service for handling user authentication with Supabase
class AuthService: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = AuthService()
    
    /// Current authenticated user
    @Published private(set) var currentUser: User?
    
    /// Whether the user is authenticated
    @Published private(set) var isAuthenticated: Bool = false
    
    /// Current authentication state
    @Published private(set) var authState: AuthState = .initializing
    
    /// Error message if authentication fails
    @Published var errorMessage: String?
    
    /// Supabase client instance
    private(set) var supabase: SupabaseClient
    
    /// Current user session
    @Published private(set) var session: Session?
    
    /// Storage service for persisting user data
    private let storageService: StorageService
    
    /// Keychain for secure storage
    private let keychain = Keychain(service: "com.aicompanion.auth")
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        
        // Initialize Supabase client with URL and anon key from secure storage
        guard let supabaseURLString = try? keychain.get("supabaseURL"),
              let supabaseURL = URL(string: supabaseURLString),
              let supabaseKey = try? keychain.get("supabaseKey") else {
            // Use default values for development - in production, handle this differently
            let defaultURL = URL(string: "https://your-project.supabase.co")!
            supabase = SupabaseClient(supabaseURL: defaultURL, supabaseKey: "your-anon-key")
            authState = .signedOut
            
            // Load user from storage for backward compatibility
            currentUser = storageService.loadUser()
            isAuthenticated = currentUser != nil
            
            // For this app, we'll auto-create a user if none exists
            if currentUser == nil {
                Task {
                    do {
                        _ = try await signInAsGuest()
                    } catch {
                        errorMessage = "Error creating guest user: \(error.localizedDescription)"
                    }
                }
            }
            
            return
        }
        
        supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(
                    storage: KeychainSessionStorage(),
                    flowType: .pkce
                )
            )
        )
        
        // Load user from storage for backward compatibility
        currentUser = storageService.loadUser()
        isAuthenticated = currentUser != nil
        
        // Setup session monitoring
        setupSessionMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Configure Supabase with URL and API key
    func configure(url: String, apiKey: String) {
        do {
            try keychain.set(url, key: "supabaseURL")
            try keychain.set(apiKey, key: "supabaseKey")
            
            // Reinitialize client with new credentials
            guard let supabaseURL = URL(string: url) else {
                return
            }
            
            supabase = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: apiKey,
                options: SupabaseClientOptions(
                    auth: .init(
                        storage: KeychainSessionStorage(),
                        flowType: .pkce
                    )
                )
            )
            
            // Setup session monitoring with new client
            setupSessionMonitoring()
        } catch {
            print("Error storing Supabase credentials: \(error)")
        }
    }
    
    /// Sign up a new user with email and password
    func signUp(email: String, password: String) async throws -> User {
        authState = .loading
        errorMessage = nil
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            if let session = authResponse.session {
                self.session = session
                authState = .signedIn
                
                // Create a new user with the Supabase user ID
                let user = User(
                    id: session.user.id,
                    username: email.components(separatedBy: "@").first ?? "User",
                    email: email,
                    preferences: UserPreferences(),
                    apiKeys: [:]
                )
                
                // Save the user
                storageService.saveUser(user)
                
                // Update state
                await MainActor.run {
                    currentUser = user
                    isAuthenticated = true
                }
                
                return user
            } else {
                // Email confirmation required
                authState = .confirmationRequired
                throw NSError(domain: "AICompanion", code: 401, userInfo: [NSLocalizedDescriptionKey: "Email confirmation required"])
            }
        } catch {
            authState = .error(error)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> User {
        authState = .loading
        errorMessage = nil
        
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            session = authResponse.session
            authState = .signedIn
            
            // Check if we have a user with this ID
            if let existingUser = storageService.loadUser(), existingUser.id == authResponse.session.user.id {
                // Update existing user
                let user = User(
                    id: existingUser.id,
                    username: existingUser.username,
                    email: email,
                    preferences: existingUser.preferences,
                    apiKeys: existingUser.apiKeys
                )
                
                // Save the user
                storageService.saveUser(user)
                
                // Update state
                await MainActor.run {
                    currentUser = user
                    isAuthenticated = true
                }
                
                return user
            } else {
                // Create new user
                let user = User(
                    id: authResponse.session.user.id,
                    username: email.components(separatedBy: "@").first ?? "User",
                    email: email,
                    preferences: UserPreferences(),
                    apiKeys: [:]
                )
                
                // Save the user
                storageService.saveUser(user)
                
                // Update state
                await MainActor.run {
                    currentUser = user
                    isAuthenticated = true
                }
                
                return user
            }
        } catch {
            authState = .error(error)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in with magic link (passwordless)
    func signInWithMagicLink(email: String) async throws {
        authState = .loading
        errorMessage = nil
        
        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                options: .init(
                    emailRedirectTo: URL(string: "aicompanion://login-callback")
                )
            )
            authState = .magicLinkSent
        } catch {
            authState = .error(error)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in with OAuth provider
    func signInWithOAuth(provider: OAuthProvider) async throws {
        authState = .loading
        errorMessage = nil
        
        do {
            try await supabase.auth.signInWithOAuth(
                provider: provider,
                options: .init(
                    redirectTo: URL(string: "aicompanion://login-callback")
                )
            )
            // Note: The actual sign-in will happen when the OAuth callback is processed
        } catch {
            authState = .error(error)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in as a guest user (for backward compatibility)
    func signInAsGuest() async throws -> User {
        // Clear any previous error
        errorMessage = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Create a guest user
        let guestId = UUID()
        let user = User(
            id: guestId,
            username: "Guest User",
            email: "guest@example.com",
            preferences: UserPreferences(
                isDarkMode: false,
                defaultAIProviderId: SampleData.getSampleAIProviders().first?.id,
                fontSize: 14,
                showTimestamps: true,
                saveChatHistory: true,
                maxConversationHistory: 50,
                showUserAvatars: true,
                showAIAvatars: true,
                messageSpacing: 1.0
            ),
            apiKeys: [:]
        )
        
        // Save the user
        storageService.saveUser(user)
        
        // Update state
        await MainActor.run {
            currentUser = user
            isAuthenticated = true
            authState = .signedIn
        }
        
        return user
    }
    
    /// Sign out the current user
    func signOut() async throws {
        authState = .loading
        errorMessage = nil
        
        do {
            try await supabase.auth.signOut()
            session = nil
            authState = .signedOut
            
            // Clear current user
            currentUser = nil
            isAuthenticated = false
        } catch {
            authState = .error(error)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Reset password for a user
    func resetPassword(email: String) async throws {
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(
                email,
                options: .init(
                    redirectTo: URL(string: "aicompanion://reset-password")
                )
            )
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Update user password
    func updatePassword(newPassword: String) async throws {
        errorMessage = nil
        
        do {
            try await supabase.auth.updateUser(
                .init(password: newPassword)
            )
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Process deep link URL (for OAuth and magic link callbacks)
    func processDeepLink(url: URL) async {
        do {
            try await supabase.auth.session(from: url)
            // Session will be updated via the session monitoring
        } catch {
            print("Error processing deep link: \(error)")
            errorMessage = error.localizedDescription
            authState = .error(error)
        }
    }
    
    /// Update the current user
    func updateUser(_ user: User) {
        // Save the updated user
        storageService.saveUser(user)
        
        // Update state
        currentUser = user
    }
    
    /// Update user preferences
    func updatePreferences(_ preferences: UserPreferences) {
        guard var user = currentUser else { return }
        
        // Update preferences
        user.preferences = preferences
        
        // Save the updated user
        updateUser(user)
    }
    
    /// Update API key for a provider
    func updateAPIKey(for providerId: UUID, key: String) {
        guard var user = currentUser else { return }
        
        // Update API key
        user.apiKeys[providerId.uuidString] = key
        
        // Save the updated user
        updateUser(user)
    }
    
    /// Delete the current user account
    func deleteAccount() async throws {
        // Clear any previous error
        errorMessage = nil
        
        do {
            // Delete the user from Supabase
            try await supabase.auth.admin.deleteUser(id: currentUser?.id ?? UUID())
            
            // Clear user data
            try await storageService.clearAllData()
            
            // Update state
            await MainActor.run {
                currentUser = nil
                isAuthenticated = false
                authState = .signedOut
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Setup session monitoring to track auth state changes
    private func setupSessionMonitoring() {
        // Cancel any existing subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Check for existing session
        Task {
            do {
                let currentSession = try await supabase.auth.session
                DispatchQueue.main.async {
                    self.session = currentSession
                    self.authState = .signedIn
                    
                    // Check if we have a user with this ID
                    if let existingUser = self.storageService.loadUser(), existingUser.id == currentSession.user.id {
                        // Use existing user
                        self.currentUser = existingUser
                        self.isAuthenticated = true
                    } else if let email = currentSession.user.email {
                        // Create new user
                        let user = User(
                            id: currentSession.user.id,
                            username: email.components(separatedBy: "@").first ?? "User",
                            email: email,
                            preferences: UserPreferences(),
                            apiKeys: [:]
                        )
                        
                        // Save the user
                        self.storageService.saveUser(user)
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.session = nil
                    self.authState = .signedOut
                    
                    // For backward compatibility, check if we have a local user
                    if let existingUser = self.storageService.loadUser() {
                        self.currentUser = existingUser
                        self.isAuthenticated = true
                    }
                }
            }
        }
        
        // Subscribe to auth state changes
        Task {
            for await state in supabase.auth.authStateChanges {
                DispatchQueue.main.async {
                    switch state.event {
                    case .initialSession:
                        self.session = state.session
                        self.authState = state.session != nil ? .signedIn : .signedOut
                        
                        if let session = state.session, let email = session.user.email {
                            // Check if we have a user with this ID
                            if let existingUser = self.storageService.loadUser(), existingUser.id == session.user.id {
                                // Use existing user
                                self.currentUser = existingUser
                                self.isAuthenticated = true
                            } else {
                                // Create new user
                                let user = User(
                                    id: session.user.id,
                                    username: email.components(separatedBy: "@").first ?? "User",
                                    email: email,
                                    preferences: UserPreferences(),
                                    apiKeys: [:]
                                )
                                
                                // Save the user
                                self.storageService.saveUser(user)
                                self.currentUser = user
                                self.isAuthenticated = true
                            }
                        }
                    case .signedIn:
                        self.session = state.session
                        self.authState = .signedIn
                        
                        if let session = state.session, let email = session.user.email {
                            // Check if we have a user with this ID
                            if let existingUser = self.storageService.loadUser(), existingUser.id == session.user.id {
                                // Use existing user
                                self.currentUser = existingUser
                                self.isAuthenticated = true
                            } else {
                                // Create new user
                                let user = User(
                                    id: session.user.id,
                                    username: email.components(separatedBy: "@").first ?? "User",
                                    email: email,
                                    preferences: UserPreferences(),
                                    apiKeys: [:]
                                )
                                
                                // Save the user
                                self.storageService.saveUser(user)
                                self.currentUser = user
                                self.isAuthenticated = true
                            }
                        }
                    case .signedOut:
                        self.session = nil
                        self.authState = .signedOut
                        self.currentUser = nil
                        self.isAuthenticated = false
                    case .userUpdated:
                        self.session = state.session
                    case .passwordRecovery:
                        self.authState = .passwordRecovery
                    case .tokenRefreshed:
                        self.session = state.session
                    default:
                        break
                    }
                }
            }
        }
    }
}

/// Keychain-based session storage for Supabase
class KeychainSessionStorage: LocalStorage {
    private let keychain = Keychain(service: "com.aicompanion.auth.session")
    
    func set(key: String, value: String) {
        try? keychain.set(value, key: key)
    }
    
    func get(key: String) -> String? {
        try? keychain.get(key)
    }
    
    func remove(key: String) {
        try? keychain.remove(key)
    }
}
