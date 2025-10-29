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
            self.videos = try await supabase.loadAllVideos()
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Load only videos from following list
    func loadFollowingVideos() async {
        isLoading = true
        errorMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            self.videos = try await supabase.loadFollowingVideos(currentUserId: currentUser.id)
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
