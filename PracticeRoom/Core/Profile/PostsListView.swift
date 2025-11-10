//
//  PostsListView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/20/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct PostsListView: View {
    @StateObject private var videoViewModel = VideoViewModel()
    @State private var selectedVideo: Video?
    let userId: UUID?
    
    init(userId: UUID? = nil) {
        self.userId = userId
    }
    
    // grid layout - 3 columns
    let columns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]
    
    var body: some View {
        Group {
            if videoViewModel.isLoading {
                ProgressView("Loading videos...")
            } else if videoViewModel.videos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                    Text("No videos uploaded yet")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(videoViewModel.videos) { video in
                            VideoThumbnailView(video: video)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedVideo = video
                                }
                        }
                    }
                }
            }
        }
        .task {
            await videoViewModel.loadVideos(userId: userId)
        }
        .fullScreenCover(item: $selectedVideo) { video in
            NavigationStack {
                VideoPlayerView(video: video)
            }
        }
    }
}

// thumbnail view for grid
struct VideoThumbnailView: View {
    let video: Video
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // thumbnail image or placeholder
            if let thumbnailImage = thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            
            // video title overlay
            VStack(alignment: .leading, spacing: 2) {
                Text(video.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(radius: 2)
            }
            .padding(8)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard let url = URL(string: video.videoUrl) else {
            isLoading = false
            return
        }
        
        Task {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try await imageGenerator.image(at: CMTime.zero).image
                await MainActor.run {
                    self.thumbnailImage = UIImage(cgImage: cgImage)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    PostsListView()
}
