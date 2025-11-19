// Models.swift
//
// Purpose:
// - Define application data models
// - Define encoding usages
//      - Encodable: Only sending this data to backend. Model is write-only from app's perspective.
//      - Decodable: Only receiving this data from backend. Model is read-only from app's perspective.
//      - Codable: Both send and receive this data from backend. Bidirectional and symmetric entity.
//      - Identifiable: Track items in "List"s or "ForEach"s
// - Convert Swift camel case to Supabase snake case
// - "?" makes fields optional

import Foundation

// MARK: --------------- PROFILE MODELS ---------------

/// Params for creating a new user profile during initial registration
/// **Encodable** - only sent to backend when user first creates their profile
struct ProfileSetupParams: Encodable {
    let id: String
    let username: String
    let fullName: String
    let instrument: String
    let avatarUrl: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case instrument
        case avatarUrl = "avatar_url"
        case bio
    }
}

/// User profile data received from backend
/// **Decodable & Identifiable** - read-only model for displaying profile info, used in SwiftUI lists
struct Profile: Decodable, Identifiable {
    let id: UUID
    let username: String?
    let fullName: String?
    let instrument: String?
    let avatarUrl: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case instrument
        case avatarUrl = "avatar_url"
        case bio
  }
}

/// Parameters for updating an existing user profile
/// **Encodable** - sent to backend when user updates profile
struct UpdateProfileParams: Encodable {
    let username: String
    let fullName: String
    let instrument: String
    let avatarUrl: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
        case instrument
        case avatarUrl = "avatar_url"
        case bio
  }
}

// MARK: --------------- VIDEO MODELS ---------------

/// Video entity (metadata + storage Url) for user posts
/// **Decodable & Identifiable** - read-only model received from backend, identifiable for feeds and profile grids
struct Video: Identifiable, Decodable {
    let id: UUID
    let title: String
    let description: String?
    let videoUrl: String
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case videoUrl = "video_url"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Video entity (metadata + storage Url) for user posts
/// **Encodable** - used for sending video to backend. id, createdAt/updatedAt are generated automatically by Supabase
struct VideoUpload: Encodable {
    let title: String
    let description: String?
    let videoUrl: String
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case videoUrl = "video_url"
        case userId = "user_id"
    }
}

// MARK: --------------- FOLLOW MODELS ---------------

/// Follow relationship between two users
/// **Decodable & Identifiable** - read-only model received from backend, used in follow lists
struct Follow: Identifiable, Decodable {
    let id: UUID
    let followerId: UUID
    let followingId: UUID
    let status: FollowStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case status
        case createdAt = "created_at"
    }
}

enum FollowStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

/// Parameters for creating a new follow relationship
/// **Encodable** - sent to backend on initial follow request
struct FollowInsert: Encodable {
    let followerId: UUID
    let followingId: UUID
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followingId = "following_id"
        case status
    }
}

/// Parameters for updating a follow request status
/// **Encodable** - sent to backend accepting/rejecting a follow request
struct FollowUpdate: Encodable {
    let status: String
}

/// Composite structure for combine a follow request with the requester's profile. Not sent/received from backend.
/// **Identifiable** - used in notifications lists
struct PendingFollowRequest: Identifiable {
    let id: UUID
    let followRequest: Follow
    let fromUserProfile: Profile
}

// MARK: --------------- COMMENT MODELS ---------------

/// Comment on a video with structured feedback
/// **Decodable & Identifiable** - read-only model for fetching comments for a videoId
struct Comment: Identifiable, Decodable {
    let id: UUID
    let videoId: UUID
    let userId: UUID
    let goodThing: String  // required
    let improvement: String?  // optional
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case videoId = "video_id"
        case userId = "user_id"
        case goodThing = "good_thing"
        case improvement
        case createdAt = "created_at"
    }
}

/// Parameters for creating a new comment on a video
/// **Encodable** - sent to backend when user posts a comment
struct CommentInsert: Encodable {
    let videoId: UUID
    let userId: UUID
    let goodThing: String
    let improvement: String?
    
    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case userId = "user_id"
        case goodThing = "good_thing"
        case improvement
    }
}

/// Composit model combining a comment with the commenter's profile. Not sent/fetched from backend
/// **Identifiable** - used in SwiftUI comment lists
struct CommentWithProfile: Identifiable {
    let id: UUID
    let comment: Comment
    let profile: Profile
}
