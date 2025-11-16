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
@preconcurrency import AVFoundation

extension AVAssetExportSession: @unchecked @retroactive Sendable {}

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
        guard let selectedVideoItem = selectedVideo else { return }
        isUploading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let currentUser = try await supabase.getCurrentUser()
            
            guard let videoData = try await selectedVideoItem.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load video data."
                isUploading = false
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try videoData.write(to: tempURL)
            
            let asset = AVURLAsset(url: tempURL)
            let maxDurationSeconds: Double = 60
            
            let assetDuration = try await asset.load(.duration)
            if CMTimeGetSeconds(assetDuration) > maxDurationSeconds {
                errorMessage = "Videos must be 60 seconds or less"
                try? FileManager.default.removeItem(at: tempURL)
                isUploading = false
                return
            }
            let compressedData = try await export(asset: asset, preset: AVAssetExportPresetMediumQuality)
            try? FileManager.default.removeItem(at: tempURL) // clean up temp file
            
            try await supabase.uploadVideo(
                videoData: compressedData,
                userId: currentUser.id,
                title: videoTitle,
                description: videoDescription.isEmpty ? nil : videoDescription
            )
            
            // reset UI state
            self.selectedVideo = nil
            videoTitle = ""
            videoDescription = ""
            showUploadSheet = false
            
            await loadVideos()
            successMessage = "Video uploaded successfully!"
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
    
    private func export(asset: AVAsset, preset: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
                continuation.resume(throwing: NSError(
                    domain: "VideoExport",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to create export session"]
                ))
                return
            }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")

            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true

            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    do {
                        let data = try Data(contentsOf: outputURL)
                        try? FileManager.default.removeItem(at: outputURL)
                        continuation.resume(returning: data)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failed, .cancelled:
                    let error = exportSession.error ?? NSError(
                        domain: "VideoExport",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Export failed"]
                    )
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
        }
    }
}
