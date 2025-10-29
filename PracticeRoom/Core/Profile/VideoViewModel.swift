//
//  VideoViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/15/25.
//

import Foundation
import Supabase
import Combine
import PhotosUI
import _PhotosUI_SwiftUI

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = [] // list for videos in UI grid
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Video upload props
    @Published var selectedVideo: PhotosPickerItem?
    @Published var videoTitle = ""
    @Published var videoDescription = ""
    @Published var showUploadSheet = false
    
    func loadVideos(userId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            let targetUserId = userId ?? currentUser.id
            self.videos = try await supabase.loadVideos(userId: targetUserId)
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func uploadVideo() async {
        guard let selectedVideo = selectedVideo else { return }
        isUploading = true
        errorMessage = nil
        successMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            // get video data
            guard let videoData = try await selectedVideo.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load video data."
                isUploading = false
                return
            }
            // upload video
            try await supabase.uploadVideo(
                videoData: videoData,
                userId: currentUser.id,
                title: videoTitle,
                description: videoDescription.isEmpty ? nil : videoDescription
            )
            // Clear form
            self.selectedVideo = nil
            self.videoTitle = ""
            self.videoDescription = ""
            self.showUploadSheet = false
            // reload videos
            await loadVideos()
        } catch {
            errorMessage = "Failed to upload video: \(error.localizedDescription)"
        }
        isUploading = false
    }
    
    func deleteVideo(_ video: Video) async {
        do {
            try await supabase.deleteVideo(videoId: video.id)
            await loadVideos()
        } catch {
            errorMessage = "Failed to delete video: \(error.localizedDescription)"
        }
    }
}
