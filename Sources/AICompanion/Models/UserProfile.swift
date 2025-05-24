
import Foundation

/// User profile model
struct UserProfile: Codable, Identifiable, Equatable {
    /// User ID (matches auth.users.id)
    let id: UUID
    
    /// Display name
    var displayName: String?
    
    /// User bio
    var bio: String?
    
    /// Avatar URL
    var avatarURL: String?
    
    /// Created at timestamp
    var createdAt: Date?
    
    /// Updated at timestamp
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case bio
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID, displayName: String? = nil, bio: String? = nil, avatarURL: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
