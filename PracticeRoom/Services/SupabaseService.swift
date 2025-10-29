//
//  SupabaseService.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import Foundation
import Supabase
import UIKit
import PhotosUI

let supabase = SupabaseClient(
    supabaseURL: Environment.supabaseURL,
    supabaseKey: Environment.supabaseKey
)

extension SupabaseClient {
    
    // ------- AUTHENTICATION -------
    
    // Sign in with magic link
    func signInWithMagicLink(email: String) async throws {
        try await self.auth.signInWithOTP(email: email)
    }
    
    // Handle magic link callback
    func handleMagicLinkCallback(url: URL) async throws {
        try await self.auth.session(from: url)
    }
    
    // Sign out current user
    func signOut() async throws {
        try await self.auth.signOut()
    }
    
    // Get current session
    func getCurrentSession() async throws -> Session {
        return try await self.auth.session
    }
    
    // Get current user
    func getCurrentUser() async throws -> User {
        return try await self.auth.session.user
    }
    
    // ------- PROFILE OPERATIONS -------
    
    // Load profile by user ID
    func loadProfile(userId: UUID) async throws -> Profile {
        let profile: Profile = try await self
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return profile
    }
    
    // Check if username is available
    func checkUsernameAvailability(username: String, excluding userId: UUID? = nil) async throws -> Bool {
        var query = self
            .from("profiles")
            .select()
            .eq("username", value: username)
        
        if let userId = userId {
            query = query.neq("id", value: userId)
        }
        
        let profiles: [Profile] = try await query
            .execute()
            .value
        
        return profiles.isEmpty
    }
    
    // Update profile
    func updateProfile(userId: UUID, params: UpdateProfileParams) async throws {
        try await self
            .from("profiles")
            .update(params)
            .eq("id", value: userId)
            .execute()
    }
    
    // Setup/upsert profile
    func upsertProfile(params: ProfileSetupParams) async throws {
        try await self
            .from("profiles")
            .upsert(params)
            .execute()
    }
    
    // Upload avatar image to storage and return public URL
    func uploadAvatar(image: UIImage, userId: UUID) async throws -> String {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let fileExtension = "jpg"
        let fileName = "\(userId.uuidString).\(fileExtension)"
        let filePath = "\(userId.uuidString)/\(fileName)"

        try await self.storage
            .from("avatars")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true // allow overwriting existing data
                )
            )
        
        let publicURL = try self.storage
            .from("avatars")
            .getPublicURL(path: filePath)
        
        return publicURL.absoluteString
    }
    
    // Search users by username pattern
    func searchUsers(query: String, excludingUserId: UUID) async throws -> [Profile] {
        let results: [Profile] = try await self
            .from("profiles")
            .select()
            .ilike("username", pattern: "%\(query)%")
            .neq("id", value: excludingUserId)
            .execute()
            .value
        return results
    }
    
    // ------- VIDEO OPERATIONS -------
    
    // Load videos for a specific user
    func loadVideos(userId: UUID) async throws -> [Video] {
        let userIdString = userId.uuidString.lowercased()
        
        let videos: [Video] = try await self
            .from("videos")
            .select()
            .eq("user_id", value: userIdString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return videos
    }
    
    // Load all videos (for global feed)
    func loadAllVideos() async throws -> [Video] {
        let videos: [Video] = try await self
            .from("videos")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return videos
    }
    
    // Load videos from users that current user follows
    func loadFollowingVideos(currentUserId: UUID) async throws -> [Video] {
        let currentUserIdString = currentUserId.uuidString.lowercased()
        
        // Get list of users current user follows
        let follows: [Follow] = try await self
            .from("follows")
            .select()
            .eq("follower_id", value: currentUserIdString)
            .execute()
            .value
        
        let followingIds = follows.map { $0.followingId.uuidString.lowercased() }
        
        guard !followingIds.isEmpty else {
            return []
        }
        
        // Get videos from followed users
        let videos: [Video] = try await self
            .from("videos")
            .select()
            .in("user_id", values: followingIds)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return videos
    }
    
    // Upload video to storage and save metadata to database
    func uploadVideo(
        videoData: Data,
        userId: UUID,
        title: String,
        description: String?
    ) async throws {
        // Generate unique filename
        let fileName = "\(UUID().uuidString).mp4"
        let uploadPath = "\(userId.uuidString)/\(fileName)"
        
        // Upload to Supabase storage
        try await self.storage
            .from("videos")
            .upload(
                uploadPath,
                data: videoData,
                options: FileOptions(contentType: "video/mp4")
            )
        
        // Get public URL
        let publicURL = try self.storage
            .from("videos")
            .getPublicURL(path: uploadPath)
        
        // Save metadata to database
        let videoUpload = VideoUpload(
            title: title,
            description: description,
            videoUrl: publicURL.absoluteString,
            userId: userId
        )
        
        try await self
            .from("videos")
            .insert(videoUpload)
            .execute()
    }
    
    // Delete video from database
    func deleteVideo(videoId: UUID) async throws {
        try await self
            .from("videos")
            .delete()
            .eq("id", value: videoId)
            .execute()
    }
    
    // ------- FOLOW OPERATIONS -------
    
    // Check if current user is following a specific user
    func checkIfFollowing(followerId: UUID, followingId: UUID) async throws -> Bool {
        let follows: [Follow] = try await self
            .from("follows")
            .select()
            .eq("follower_id", value: followerId.uuidString.lowercased())
            .eq("following_id", value: followingId.uuidString.lowercased())
            .execute()
            .value
        
        return !follows.isEmpty
    }
    
    // Get follower count for a user
    func getFollowerCount(userId: UUID) async throws -> Int {
        let userIdString = userId.uuidString.lowercased()
        
        let followers: [Follow] = try await self
            .from("follows")
            .select()
            .eq("following_id", value: userIdString)
            .execute()
            .value
        
        return followers.count
    }
    
    // Get following count for a user
    func getFollowingCount(userId: UUID) async throws -> Int {
        let userIdString = userId.uuidString.lowercased()
        
        let following: [Follow] = try await self
            .from("follows")
            .select()
            .eq("follower_id", value: userIdString)
            .execute()
            .value
        
        return following.count
    }
    
    // Follow a user
    func followUser(followerId: UUID, followingId: UUID) async throws {
        let followInsert = FollowInsert(
            followerId: followerId,
            followingId: followingId
        )
        
        try await self
            .from("follows")
            .insert(followInsert)
            .execute()
    }
    
    // Unfollow a user
    func unfollowUser(followerId: UUID, followingId: UUID) async throws {
        try await self
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId.uuidString.lowercased())
            .eq("following_id", value: followingId.uuidString.lowercased())
            .execute()
    }
}
