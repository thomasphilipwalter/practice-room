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
    
    func checkIfFollowing(userId: UUID) async {
        do {
            let currentUser = try await supabase.getCurrentUser()
            isFollowing = try await supabase.checkIfFollowing(
                followerId: currentUser.id,
                followingId: userId
            )
        } catch {
            print("Error checking follow status: \(error)")
            errorMessage = "Failed to check follow status"
        }
    }
    
    func loadFollowCounts(userId: UUID) async {
        do {
            followerCount = try await supabase.getFollowerCount(userId: userId)
            followingCount = try await supabase.getFollowingCount(userId: userId)
        } catch {
            print("Error loading follow counts: \(error)")
            errorMessage = "Failed to load follow counts"
        }
    }
    
    func followUser(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            try await supabase.followUser(
                followerId: currentUser.id,
                followingId: userId
            )
            isFollowing = true
            followerCount += 1
        } catch {
            print("Error following user: \(error)")
            errorMessage = "Failed to follow user"
        }
        isLoading = false
    }
    
    func unfollowUser(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            try await supabase.unfollowUser(
                followerId: currentUser.id,
                followingId: userId
            )
            isFollowing = false
            followerCount -= 1
        } catch {
            print("Error unfollowing user: \(error)")
            errorMessage = "Failed to unfollow user"
        }
        isLoading = false
    }
}
