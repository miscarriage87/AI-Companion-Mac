
import Foundation
import Combine
import SwiftUI

/// ViewModel for handling authentication-related UI logic
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Email input for login/signup
    @Published var email = ""
    
    /// Password input for login/signup
    @Published var password = ""
    
    /// Password confirmation for signup
    @Published var confirmPassword = ""
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    /// Success message
    @Published var successMessage: String?
    
    /// Authentication service
    private let authService = AuthService.shared
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Subscribe to auth state changes
        authService.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .loading:
                    self.isLoading = true
                    self.errorMessage = nil
                case .error(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                case .magicLinkSent:
                    self.isLoading = false
                    self.successMessage = "Magic link sent! Check your email."
                case .confirmationRequired:
                    self.isLoading = false
                    self.successMessage = "Registration successful! Please check your email to confirm your account."
                default:
                    self.isLoading = false
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Sign up a new user
    func signUp() async {
        guard validateSignUpInputs() else { return }
        
        do {
            try await authService.signUp(email: email, password: password)
            resetFields()
        } catch {
            // Error is handled via the authState publisher
        }
    }
    
    /// Sign in an existing user
    func signIn() async {
        guard validateSignInInputs() else { return }
        
        do {
            try await authService.signIn(email: email, password: password)
            resetFields()
        } catch {
            // Error is handled via the authState publisher
        }
    }
    
    /// Sign in with magic link (passwordless)
    func signInWithMagicLink() async {
        guard validateEmail() else { return }
        
        do {
            try await authService.signInWithMagicLink(email: email)
        } catch {
            // Error is handled via the authState publisher
        }
    }
    
    /// Sign in with Apple
    func signInWithApple() async {
        do {
            try await authService.signInWithOAuth(provider: "apple")
        } catch {
            // Error is handled via the authState publisher
        }
    }
    
    /// Sign in with Google
    func signInWithGoogle() async {
        do {
            try await authService.signInWithOAuth(provider: "google")
        } catch {
            // Error is handled via the authState publisher
        }
    }
    
    /// Sign out the current user
    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            // Error is handled via the authState publisher
        }
    }
    
    /// Reset password
    func resetPassword() async {
        guard validateEmail() else { return }
        
        do {
            try await authService.resetPassword(email: email)
            successMessage = "Password reset instructions sent to your email."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Process deep link URL (for OAuth and magic link callbacks)
    func processDeepLink(url: URL) async {
        await authService.processDeepLink(url: url)
    }
    
    // MARK: - Private Methods
    
    /// Validate sign up inputs
    private func validateSignUpInputs() -> Bool {
        // Reset error message
        errorMessage = nil
        
        // Validate email
        guard validateEmail() else { return false }
        
        // Validate password
        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty"
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        // Validate password confirmation
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return false
        }
        
        return true
    }
    
    /// Validate sign in inputs
    private func validateSignInInputs() -> Bool {
        // Reset error message
        errorMessage = nil
        
        // Validate email
        guard validateEmail() else { return false }
        
        // Validate password
        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty"
            return false
        }
        
        return true
    }
    
    /// Validate email
    private func validateEmail() -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Email cannot be empty"
            return false
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        return true
    }
    
    /// Reset input fields
    private func resetFields() {
        email = ""
        password = ""
        confirmPassword = ""
    }
}
