//
//  FollowViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/24/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class FollowViewModel: ObservableObject {
    @Published var isFollowing = false
    @Published var followerCount = 0
    @Published var followingCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // check if current user is following a specific user
    func checkIfFollowing(userId: UUID) async {
        do {
            let currentUser = try await supabase.auth.session.user
            
            let follows: [Follow] = try await supabase
                .from("follows")
                .select()
                .eq("follower_id", value: currentUser.id.uuidString.lowercased())
                .eq("following_id", value: userId.uuidString.lowercased())
                .execute()
                .value
            
            isFollowing = !follows.isEmpty
        } catch {
            print("Error checking follow status: \(error)")
            errorMessage = "Failed to check follow status"
        }
    }
    
    // load follower and following counts
    func loadFollowCounts(userId: UUID) async {
        do {
            let userIdString = userId.uuidString.lowercased()
            
            // Get follower count (people following this user)
            let followers: [Follow] = try await supabase
                .from("follows")
                .select()
                .eq("following_id", value: userIdString)
                .execute()
                .value
            
            followerCount = followers.count
            
            // Get following count (people this user follows)
            let following: [Follow] = try await supabase
                .from("follows")
                .select()
                .eq("follower_id", value: userIdString)
                .execute()
                .value
            
            followingCount = following.count
        } catch {
            print("Error loading follow counts: \(error)")
            errorMessage = "Failed to load follow counts"
        }
    }
    
    // follow a user
    func followUser(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            
            let followInsert = FollowInsert(
                followerId: currentUser.id,
                followingId: userId
            )
            
            try await supabase
                .from("follows")
                .insert(followInsert)
                .execute()
            
            isFollowing = true
            followerCount += 1
        } catch {
            print("Error following user: \(error)")
            errorMessage = "Failed to follow user"
        }
        
        isLoading = false
    }
    
    // unfollow a user
    func unfollowUser(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            
            try await supabase
                .from("follows")
                .delete()
                .eq("follower_id", value: currentUser.id.uuidString.lowercased())
                .eq("following_id", value: userId.uuidString.lowercased())
                .execute()
            
            isFollowing = false
            followerCount -= 1
        } catch {
            print("Error unfollowing user: \(error)")
            errorMessage = "Failed to unfollow user"
        }
        
        isLoading = false
    }
}
