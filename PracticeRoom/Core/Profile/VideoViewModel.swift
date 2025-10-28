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
            let currentUser = try await supabase.auth.session.user
            
            let targetUserId = userId ?? currentUser.id
            
            // CONVERT TO LOWER CASE FOR THE QUERY
            let userIdString = targetUserId.uuidString.lowercased()
            
            let videos: [Video] = try await supabase
                .from("videos")
                .select()
                .eq("user_id", value: userIdString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.videos = videos
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
            let session = try await supabase.auth.session
            let currentUser = session.user
            
            // get video data
            guard let videoData = try await selectedVideo.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load video data."
                isUploading = false
                return
            }
            
            // generate unique filename
            let fileName = "\(UUID().uuidString).mp4"
            let uploadPath = "\(currentUser.id)/\(fileName)"
            
            
            // Upload to Supabase storage
            let _ = try await supabase.storage
                .from("videos")
                .upload(
                    uploadPath,
                    data: videoData,
                    options: FileOptions(contentType: "video/mp4")
                )
            
            // get public URL
            let publicURL = try supabase.storage
                    .from("videos")
                    .getPublicURL(path: uploadPath)
            
            // save metadata to database
            let videoUpload = VideoUpload(
                title: videoTitle,
                description: videoDescription.isEmpty ? nil : videoDescription,
                videoUrl: publicURL.absoluteString,
                userId: currentUser.id
            )
            
            try await supabase
                .from("videos")
                .insert(videoUpload)
                .execute()
            
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
            // delete from database
            try await supabase
                .from("videos")
                .delete()
                .eq("id", value: video.id)
                .execute()
            
            // DELETE FROM STORAGE (optional)
            // TODO: Define protocol for how long deleted videos are stored
            
            // Reload videos
            await loadVideos()
        } catch {
            errorMessage = "Failed to delete video: \(error.localizedDescription)"
        }
    }
}
