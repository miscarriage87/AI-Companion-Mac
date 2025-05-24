
import Foundation
import Combine
import SwiftUI
import Supabase

/// ViewModel for handling user profile management
class ProfileViewModel: ObservableObject {
    // MARK: - Properties
    
    /// User profile data
    @Published var profile: UserProfile?
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    /// Success message
    @Published var successMessage: String?
    
    /// Form fields
    @Published var displayName = ""
    @Published var bio = ""
    @Published var avatarURL = ""
    
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
                
                if case .signedIn = state {
                    Task {
                        await self.fetchUserProfile()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Fetch user profile from Supabase
    @MainActor
    func fetchUserProfile() async {
        guard let userId = authService.session?.user.id else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await authService.supabase.database
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            
            // Annahme: response.data ist Data? oder [String: Any]?
            guard let data = response.data else {
                throw NSError(domain: "Profile", code: 0, userInfo: [NSLocalizedDescriptionKey: "No profile data"])
            }
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)

            self.profile = profile
            self.displayName = profile.displayName ?? ""
            self.bio = profile.bio ?? ""
            self.avatarURL = profile.avatarURL ?? ""
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Update user profile
    func updateProfile() async {
        guard let userId = authService.session?.user.id else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let updatedProfile = UserProfile(
            id: userId,
            displayName: displayName,
            bio: bio,
            avatarURL: avatarURL
        )
        
        do {
            try await authService.supabase.database
                .from("profiles")
                .upsert(updatedProfile)
                .execute()
            
            DispatchQueue.main.async {
                self.profile = updatedProfile
                self.successMessage = "Profile updated successfully"
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Upload profile picture
    func uploadProfilePicture(imageData: Data) async {
        guard let userId = authService.session?.user.id else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let filePath = "avatars/\(userId)"
            
            // Upload image to Supabase Storage
            try await authService.supabase.storage
                .from("profiles")
                .upload(
                    path: filePath,
                    file: imageData,
                    options: .init(contentType: "image/jpeg")
                )
            
            // Get public URL for the uploaded image
            let publicURL = try await authService.supabase.storage
                .from("profiles")
                .getPublicURL(path: filePath)
            
            DispatchQueue.main.async {
                self.avatarURL = publicURL.absoluteString
                
                // Update profile with new avatar URL
                Task {
                    await self.updateProfile()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to upload profile picture: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
