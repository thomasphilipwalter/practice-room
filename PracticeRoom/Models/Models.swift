//
//  Models.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import Foundation

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

struct Video: Identifiable, Codable {
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

struct Follow: Identifiable, Codable {
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

struct FollowUpdate: Encodable {
    let status: String
}

struct PendingFollowRequest: Identifiable {
    let id: UUID
    let followRequest: Follow
    let fromUserProfile: Profile
}
