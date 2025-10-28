//
//  FeedViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/24/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Load all videos for global feed
    func loadAllVideos() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let videos: [Video] = try await supabase
                .from("videos")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.videos = videos
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Load videos only from users the current user follows
    func loadFollowingVideos() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            let currentUserId = currentUser.id.uuidString.lowercased()
            
            // Get list of users current user follows
            let follows: [Follow] = try await supabase
                .from("follows")
                .select()
                .eq("follower_id", value: currentUserId)
                .execute()
                .value
            
            let followingIds = follows.map { $0.followingId.uuidString.lowercased() }
            
            if followingIds.isEmpty {
                self.videos = []
            } else {
                // Get videos from followed users
                let videos: [Video] = try await supabase
                    .from("videos")
                    .select()
                    .in("user_id", values: followingIds)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                self.videos = videos
            }
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
