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
    @Published var followStatus: FollowStatus?
    @Published var followerCount = 0
    @Published var followingCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isFollowing: Bool {
        followStatus == .accepted
    }
    
    var isPending: Bool {
        followStatus == .pending
    }
    
    // check follow stat with target user
    func checkFollowStatus(userId: UUID) async {
        do {
            let currentUser = try await supabase.getCurrentUser()
            followStatus = try await supabase.getFollowStatus(
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
    
    // Send follow request
    func sendFollowRequest(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            try await supabase.sendFollowRequest(
                followerId: currentUser.id,
                followingId: userId
            )
            followStatus = .pending
        } catch {
            print("Error sending follow request: \(error)")
            errorMessage = "Failed to send follow request"
        }
        isLoading = false
    }
    
    func unfollowUser(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            if followStatus == .pending {
                try await supabase.cancelFollowRequest(
                    followerId: currentUser.id,
                    followingId: userId
                )
            } else {
                try await supabase.unfollowUser(
                    followerId: currentUser.id,
                    followingId: userId
                )
                followerCount = max(0, followerCount - 1)
            }
            followStatus = nil
        } catch {
            print("Error unfollowing user: \(error)")
            errorMessage = "Failed to unfollow user"
        }
        isLoading = false
    }
    
//    
//    func checkIfFollowing(userId: UUID) async {
//        do {
//            let currentUser = try await supabase.getCurrentUser()
//            isFollowing = try await supabase.checkIfFollowing(
//                followerId: currentUser.id,
//                followingId: userId
//            )
//        } catch {
//            print("Error checking follow status: \(error)")
//            errorMessage = "Failed to check follow status"
//        }
//    }
//    
//    func followUser(userId: UUID) async {
//        isLoading = true
//        errorMessage = nil
//        do {
//            let currentUser = try await supabase.getCurrentUser()
//            try await supabase.followUser(
//                followerId: currentUser.id,
//                followingId: userId
//            )
//            isFollowing = true
//            followerCount += 1
//        } catch {
//            print("Error following user: \(error)")
//            errorMessage = "Failed to follow user"
//        }
//        isLoading = false
//    }
}
