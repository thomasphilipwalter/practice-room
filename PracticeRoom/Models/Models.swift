//
//  Models.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import Foundation


struct Profile: Decodable {
    let username: String?
    let fullName: String?
    let instrument: String?

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
        case instrument
  }
}

struct UpdateProfileParams: Encodable {
    let username: String
    let fullName: String
    let instrument: String

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
        case instrument
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
