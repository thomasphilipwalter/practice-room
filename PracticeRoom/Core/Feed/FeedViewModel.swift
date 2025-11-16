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
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreVideos = true
    
    private var currentOffset = 0
    private let pageSize = 10
    private let windowSize = 20
    private var feedType: FeedType = .global
    
    enum FeedType {
        case global
        case following
    }
    
    // Load all videos for global feed
    func loadAllVideos() async {
        feedType = .global
        isLoading = true
        errorMessage = nil
        videos = []
        currentOffset = 0
        hasMoreVideos = true
        
        do {
            let newVideos = try await supabase.loadAllVideos(limit: pageSize, offset: currentOffset)
            self.videos = newVideos
            self.currentOffset = newVideos.count
            self.hasMoreVideos = newVideos.count == pageSize
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Load only videos from following list
    func loadFollowingVideos() async {
        feedType = .following
        isLoading = true
        errorMessage = nil
        videos = []
        currentOffset = 0
        hasMoreVideos = true
        
        do {
            let currentUser = try await supabase.getCurrentUser()
            let newVideos = try await supabase.loadFollowingVideos(
                currentUserId: currentUser.id,
                limit: pageSize,
                offset: currentOffset
            )
            self.videos = newVideos
            self.currentOffset = newVideos.count
            self.hasMoreVideos = newVideos.count == pageSize
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Load more videos when scrolling
    func loadMoreVideos() async {
        guard !isLoadingMore && hasMoreVideos else {
            return
        }
        
        isLoadingMore = true
        
        do {
            let newVideos: [Video]
            
            switch feedType {
            case .global:
                newVideos = try await supabase.loadAllVideos(limit: pageSize, offset: currentOffset)
            case .following:
                let currentUser = try await supabase.getCurrentUser()
                newVideos = try await supabase.loadFollowingVideos(
                    currentUserId: currentUser.id,
                    limit: pageSize,
                    offset: currentOffset
                )
            }
            
            if newVideos.isEmpty {
                hasMoreVideos = false
            } else {
                // Append new videos
                self.videos.append(contentsOf: newVideos)
                self.currentOffset += newVideos.count
                self.hasMoreVideos = newVideos.count == pageSize
                
                // Trim window if too large (remove oldest videos)
                if videos.count > windowSize {
                    let toRemove = videos.count - windowSize
                    videos.removeFirst(toRemove)
                    // Adjust offset to account for removed videos
                    currentOffset = max(0, currentOffset - toRemove)
                }
            }
        } catch {
            errorMessage = "Failed to load more videos: \(error.localizedDescription)"
        }
        
        isLoadingMore = false
    }
}

