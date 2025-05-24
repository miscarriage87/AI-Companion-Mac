
import Foundation
import Supabase
import KeychainAccess
import Combine
import SwiftUI

/// Service responsible for handling authentication with Supabase
class AuthService: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = AuthService()
    
    /// Supabase client instance
    private(set) var supabase: SupabaseClient
    
    /// Current user session
    @Published private(set) var session: Session?
    
    /// Current authentication state
    @Published private(set) var authState: AuthState = .initializing
    
    /// Keychain for secure storage
    private let keychain = Keychain(service: "com.aicompanion.auth")
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize Supabase client with URL and anon key from secure storage
        guard let supabaseURLString = try? keychain.get("supabaseURL"),
              let supabaseURL = URL(string: supabaseURLString),
              let supabaseKey = try? keychain.get("supabaseKey") else {
            // Use default values for development - in production, handle this differently
            let defaultURL = URL(string: "https://your-project.supabase.co")!
            supabase = SupabaseClient(supabaseURL: defaultURL, supabaseKey: "your-anon-key")
            authState = .signedOut
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
    func signUp(email: String, password: String) async throws {
        authState = .loading
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            if let session = authResponse.session {
                self.session = session
                authState = .signedIn
            } else {
                // Email confirmation required
                authState = .confirmationRequired
            }
        } catch {
            authState = .error(error)
            throw error
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        authState = .loading
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            session = authResponse.session
            authState = .signedIn
        } catch {
            authState = .error(error)
            throw error
        }
    }
    
    /// Sign in with magic link (passwordless)
    func signInWithMagicLink(email: String) async throws {
        authState = .loading
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
            throw error
        }
    }
    
    /// Sign in with OAuth provider
    func signInWithOAuth(provider: OAuthProvider) async throws {
        authState = .loading
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
            throw error
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        authState = .loading
        do {
            try await supabase.auth.signOut()
            session = nil
            authState = .signedOut
        } catch {
            authState = .error(error)
            throw error
        }
    }
    
    /// Reset password for a user
    func resetPassword(email: String) async throws {
        do {
            try await supabase.auth.resetPasswordForEmail(
                email,
                options: .init(
                    redirectTo: URL(string: "aicompanion://reset-password")
                )
            )
        } catch {
            throw error
        }
    }
    
    /// Update user password
    func updatePassword(newPassword: String) async throws {
        do {
            try await supabase.auth.updateUser(
                .init(password: newPassword)
            )
        } catch {
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
            authState = .error(error)
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
                }
            } catch {
                DispatchQueue.main.async {
                    self.session = nil
                    self.authState = .signedOut
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
                    case .signedIn:
                        self.session = state.session
                        self.authState = .signedIn
                    case .signedOut:
                        self.session = nil
                        self.authState = .signedOut
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

// MARK: - Supporting Types

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
