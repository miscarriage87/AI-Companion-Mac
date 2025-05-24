import Foundation
import Supabase
import KeychainAccess
import Combine
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    private(set) var supabase: SupabaseClient
    @Published private(set) var session: Session?
    @Published private(set) var authState: AuthState = .initializing
    private let keychain = Keychain(service: "com.aicompanion.auth")
    private var cancellables = Set<AnyCancellable>()

    private init() {
        guard let supabaseURLString = try? keychain.get("supabaseURL"),
              let supabaseURL = URL(string: supabaseURLString),
              let supabaseKey = try? keychain.get("supabaseKey") else {
            let defaultURL = URL(string: "https://your-project.supabase.co")!
            supabase = SupabaseClient(supabaseURL: defaultURL, supabaseKey: "your-anon-key")
            authState = .signedOut
            return
        }
        supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        setupSessionMonitoring()
    }

    func configure(url: String, apiKey: String) {
        do {
            try keychain.set(url, key: "supabaseURL")
            try keychain.set(apiKey, key: "supabaseKey")
            guard let supabaseURL = URL(string: url) else { return }
            supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: apiKey)
            setupSessionMonitoring()
        } catch {
            print("Error storing Supabase credentials: \(error)")
        }
    }

    func signUp(email: String, password: String) async throws {
        authState = .loading
        do {
            let authResponse = try await supabase.auth.signUp(email: email, password: password)
if let session = authResponse.session {
    self.session = session
    authState = .signedIn
} else {
    authState = .confirmationRequired
}
        } catch {
            authState = .error(error)
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        authState = .loading
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
self.session = session
authState = .signedIn
        } catch {
            authState = .error(error)
            throw error
        }
    }

    func signInWithMagicLink(email: String) async throws {
        authState = .loading
        do {
            try await supabase.auth.signInWithOTP(email: email)
            authState = .magicLinkSent
        } catch {
            authState = .error(error)
            throw error
        }
    }

    func signInWithOAuth(provider: String) async throws {
        authState = .loading
        do {
            try await supabase.auth.signInWithOAuth(provider: Provider(rawValue: provider) ?? .google)
        } catch {
            authState = .error(error)
            throw error
        }
    }

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

    func resetPassword(email: String) async throws {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            throw error
        }
    }

    func updatePassword(newPassword: String) async throws {
        do {
            // In Supabase v2, password update is done via updateUser
            try await supabase.from("users").update(["password": newPassword]).eq("id", value: self.session?.user.id).execute()
        } catch {
            throw error
        }
    }

    func processDeepLink(url: URL) async {
        do {
            try await supabase.auth.session(from: url)
        } catch {
            print("Error processing deep link: \(error)")
            authState = .error(error)
        }
    }

    private func setupSessionMonitoring() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
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
