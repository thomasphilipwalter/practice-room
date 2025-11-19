// SupabaseService.swift
//
// Purpose:
// - Consolidate all calls to Supabase backend
// - Creates client, adds custom methods
// MARK: Pagination is implemented for loading feed videos, but not for loading comments, followers/following lists, or profile videos

import Foundation
import Supabase
import UIKit
import PhotosUI

let supabase = SupabaseClient(
    supabaseURL: Environment.supabaseURL,
    supabaseKey: Environment.supabaseKey
)

extension SupabaseClient {
    
    // MARK: ---------------  AUTHENTICATION ---------------
    
    /// Sign in with magic link
    func signInWithMagicLink(email: String) async throws {
        try await self.auth.signInWithOTP(email: email)
    }
    
    /// Handle magic link callback
    func handleMagicLinkCallback(url: URL) async throws {
        try await self.auth.session(from: url)
    }
    
    /// Sign out current user
    func signOut() async throws {
        try await self.auth.signOut()
    }
    
    /// Get current session
    func getCurrentSession() async throws -> Session {
        return try await self.auth.session
    }
    
    /// Get current user
    func getCurrentUser() async throws -> User {
        return try await self.auth.session.user
    }
    
    // MARK: --------------- PROFILE OPERATIONS ---------------
    
    /// Load profile by user ID
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
    
    /// Check if username is available, either during setup (nothing to exclude) or during username change (exclude old username)
    func checkUsernameAvailability(username: String, excluding userId: UUID? = nil) async throws -> Bool {
        var query = self
            .from("profiles")
            .select()
            .eq("username", value: username)
        
        // If userId provided (i.e. username update), availability check should include current username
        if let userId = userId {
            query = query.neq("id", value: userId)
        }
        
        let profiles: [Profile] = try await query
            .execute()
            .value
        
        return profiles.isEmpty
    }
    
    /// Update profile (works only if userId already in profile table), use for profile updates post setup/registration
    func updateProfile(userId: UUID, params: UpdateProfileParams) async throws {
        try await self
            .from("profiles")
            .update(params)
            .eq("id", value: userId)
            .execute()
    }
    
    /// Setup/upsert profile (use during setup)
    func upsertProfile(params: ProfileSetupParams) async throws {
        try await self
            .from("profiles")
            .upsert(params)
            .execute()
    }
    
    /// Upload avatar image to storage and return public URL
    /// - Generate unique id
    /// - uplaod to supabase storage
    /// - Assumes already compressed in viewModel
    func uploadAvatar(imageData: Data, userId: UUID) async throws -> String {
        // Generate unique file path
        let lowercasedId = userId.uuidString.lowercased()
        let fileExtension = "jpg"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = "\(lowercasedId)_\(timestamp).\(fileExtension)"
        let filePath = "\(lowercasedId)/\(fileName)"
        
        try await self.storage
            .from("avatars")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(
                    cacheControl: "3600", // Cache for 1 hour
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        // Get the public url
        let publicURL = try self.storage
            .from("avatars")
            .getPublicURL(path: filePath)

        return publicURL.absoluteString
    }
    
    /// Search for user profile
    func searchUsers(query: String, excludingUserId: UUID) async throws -> [Profile] {
        let results: [Profile] = try await self
            .from("profiles")
            .select()
            .ilike("username", pattern: "%\(query)%") // search case-insensitive and placement agnostic
            .neq("id", value: excludingUserId) // exclude a user (i.e. your own)
            .execute()
            .value
        return results
    }
    
    // MARK: --------------- VIDEO OPERATIONS ---------------
    
    /// Load videos for a specific user
    // MARK: NO PAGINATION FOR PROFILE VIDEOS
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
    
    /// Fetch 10 videos from global feed
    /// - Fetch 10 at a time
    /// - Start at offset 'offset' (for pagination)
    func loadAllVideos(limit: Int = 10, offset: Int = 0) async throws -> [Video] {
        let videos: [Video] = try await self
            .from("videos")
            .select()
            .order("created_at", ascending: false) // Sort newest first
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return videos
    }
    
    /// Fetch 10 videos from followers feed
    /// - Fetch 10 at a time
    /// - Start at offset 'offset' (for pagination)
    func loadFollowingVideos(currentUserId: UUID, limit: Int = 10, offset: Int = 0) async throws -> [Video] {
        let currentUserIdString = currentUserId.uuidString.lowercased()
        
        // Get list of users current user follows
        let follows: [Follow] = try await self
            .from("follows")
            .select()
            .eq("follower_id", value: currentUserIdString)
            .eq("status", value: FollowStatus.accepted.rawValue)
            .execute()
            .value
        
        // array of user ids being followed by current user
        let followingIds = follows.map { $0.followingId.uuidString.lowercased() }
        
        guard !followingIds.isEmpty else {
            return []
        }
        
        let videos: [Video] = try await self
            .from("videos")
            .select()
            .in("user_id", values: followingIds)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return videos
    }
    
    /// Upload video to storage and save metadata to database
    /// - Assumes already compressed
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
    
    /// Delete video from database
    /// - NOTE: Only deletes metadata, not actual file
    func deleteVideo(videoId: UUID) async throws {
        try await self
            .from("videos")
            .delete()
            .eq("id", value: videoId)
            .execute()
    }
    
    // MARK: --------------- FOLOW OPERATIONS ---------------
    
    /// Send a NEW follow request
    func sendFollowRequest(followerId: UUID, followingId: UUID) async throws {
        // Prevent duplicates
        let existing: [Follow] = try await self
            .from("follows")
            .select()
            .eq("follower_id", value: followerId.uuidString.lowercased())
            .eq("following_id", value: followingId.uuidString.lowercased())
            .execute()
            .value
        
        if !existing.isEmpty {
            throw NSError(
                domain: "FollowError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Follow request already exists"]
            )
        }
        
        let followInsert = FollowInsert(
            followerId: followerId,
            followingId: followingId,
            status: FollowStatus.pending.rawValue
        )
        
        try await self
            .from("follows")
            .insert(followInsert)
            .execute()
    }
    
    /// Accept a follow request (set status = accepted)
    func acceptFollowRequest(followId: UUID) async throws {
        try await self
            .from("follows")
            .update(FollowUpdate(status: FollowStatus.accepted.rawValue))
            .eq("id", value: followId.uuidString.lowercased())
            .execute()
    }
    
    /// Reject a follow request (set status = rejected)
    func rejectFollowRequest(followId: UUID) async throws {
        try await self
            .from("follows")
            .delete()
            .eq("id", value: followId.uuidString.lowercased())
            .execute()
    }
    
    /// Cancel a pending follow request you sent
    func cancelFollowRequest(followerId: UUID, followingId: UUID) async throws {
        try await self
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId.uuidString.lowercased())
            .eq("following_id", value: followingId.uuidString.lowercased())
            .eq("status", value: FollowStatus.pending.rawValue)
            .execute()
    }
    
    /// Unfollow (remove accepted follow)
    func unfollowUser(followerId: UUID, followingId: UUID) async throws {
        try await self
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId.uuidString.lowercased())
            .eq("following_id", value: followingId.uuidString.lowercased())
            .execute()
    }
    
    /// Get follow status between two users (nil if no row)
    func getFollowStatus(followerId: UUID, followingId: UUID) async throws -> FollowStatus? {
        let follows: [Follow] = try await self
            .from("follows")
            .select()
            .eq("follower_id", value: followerId.uuidString.lowercased())
            .eq("following_id", value: followingId.uuidString.lowercased())
            .execute()
            .value
        return follows.first?.status
    }
    
    /// Get pending follow requests for a user (they are the target/following)
    func getPendingFollowRequests(userId: UUID) async throws -> [Follow] {
        let userIdString = userId.uuidString.lowercased()
        let pending: [Follow] = try await self
            .from("follows")
            .select()
            .eq("following_id", value: userIdString)
            .eq("status", value: FollowStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
        return pending
    }
    
    /// Get follower count for a user (accepted only)
    func getFollowerCount(userId: UUID) async throws -> Int {
        let userIdString = userId.uuidString.lowercased()
        let followers: [Follow] = try await self
            .from("follows")
            .select()
            .eq("following_id", value: userIdString)
            .eq("status", value: FollowStatus.accepted.rawValue)
            .execute()
            .value
        return followers.count
    }
    
    /// Get following count for a user (accepted only)
    func getFollowingCount(userId: UUID) async throws -> Int {
        let userIdString = userId.uuidString.lowercased()
        let following: [Follow] = try await self
            .from("follows")
            .select()
            .eq("follower_id", value: userIdString)
            .eq("status", value: FollowStatus.accepted.rawValue)
            .execute()
            .value
        return following.count
    }
    
    /// Minimal struct to decode only id and username
    private struct UsernameRow: Decodable {
        let id: UUID
        let username: String?
    }
    
    /// Returns list of usernames from a list of ids
    private func fetchUsernames(for ids: [UUID]) async throws -> [String] {
        guard !ids.isEmpty else { return [] }
        let idStrings = ids.map { $0.uuidString.lowercased() }

        let rows: [UsernameRow] = try await self
            .from("profiles")
            .select("id, username")
            .in("id", values: idStrings)
            .order("username", ascending: true)
            .execute()
            .value

        return rows.compactMap { $0.username } // extract just usernames
    }
    
    /// Get the list of usernames that **follow** the specific user
    /// Returns a **list of usernames**
    // MARK: NO PAGINATION FOR VIDEO COMMENTS, SHOULD HAVE PAGINATION
    func getFollowerUsernames(userId: UUID) async throws -> [String] {
        let userIdString = userId.uuidString.lowercased()

        struct FollowerIdRow: Decodable {
            let followerId: String
            enum CodingKeys: String, CodingKey { case followerId = "follower_id" }
        }

        let rows: [FollowerIdRow] = try await self
            .from("follows")
            .select("follower_id")
            .eq("following_id", value: userIdString)
            .eq("status", value: FollowStatus.accepted.rawValue)
            .execute()
            .value

        let ids = rows.compactMap { UUID(uuidString: $0.followerId) }
        return try await fetchUsernames(for: ids)
    }
    
    /// Get the list of usernames are **followed by** the specific user
    /// Returns a **list of usernames**
    // MARK: NO PAGINATION FOR VIDEO COMMENTS, SHOULD HAVE PAGINATION
    func getFollowingUsernames(userId: UUID) async throws -> [String] {
        let userIdString = userId.uuidString.lowercased()

        struct FollowingIdRow: Decodable {
            let followingId: String
            enum CodingKeys: String, CodingKey { case followingId = "following_id" }
        }

        let rows: [FollowingIdRow] = try await self
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userIdString)
            .eq("status", value: FollowStatus.accepted.rawValue)
            .execute()
            .value

        let ids = rows.compactMap { UUID(uuidString: $0.followingId) }
        return try await fetchUsernames(for: ids)
    }
    
    // MARK: --------------- COMMENT OPERATIONS ---------------
    
    /// Create a comment on a video
    func createComment(videoId: UUID, userId: UUID, goodThing: String, improvement: String?) async throws {
        let commentInsert = CommentInsert(
            videoId: videoId,
            userId: userId,
            goodThing: goodThing,
            improvement: improvement
        )
        
        try await self
            .from("comments")
            .insert(commentInsert)
            .execute()
    }
    
    /// Load the comments of a video with associated profiless
    // MARK: NO PAGINATION FOR VIDEO COMMENTS, SHOULD HAVE PAGINATION
    func loadComments(videoId: UUID) async throws -> [CommentWithProfile] {
        // First get comments
        let comments: [Comment] = try await self
            .from("comments")
            .select()
            .eq("video_id", value: videoId.uuidString.lowercased())
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Get unique user IDs
        let userIds = Array(Set(comments.map { $0.userId }))
        
        // Fetch profiles for those users
        var profiles: [UUID: Profile] = [:]
        for userId in userIds {
            do {
                let profile = try await loadProfile(userId: userId)
                profiles[userId] = profile
            } catch {
                print("Failed to load profile for user \(userId): \(error)")
            }
        }
        
        // Combine comments with profiles
        return comments.compactMap { comment in
            guard let profile = profiles[comment.userId] else { return nil }
            return CommentWithProfile(id: comment.id, comment: comment, profile: profile)
        }
    }
}
