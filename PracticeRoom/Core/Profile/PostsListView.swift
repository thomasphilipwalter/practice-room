//
//  PostsListView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/20/25.
//

import SwiftUI
import PhotosUI

struct PostsListView: View {
    @StateObject private var videoViewModel = VideoViewModel()
    @State private var selectedVideo: Video?
    let userId: UUID?
    
    init(userId: UUID? = nil) {
        self.userId = userId
    }
    
    // grid layout - 3 columns
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        Group {
            if videoViewModel.isLoading {
                ProgressView("Loading videos...")
            } else if videoViewModel.videos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No videos uploaded yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(videoViewModel.videos) { video in
                            VideoThumbnailView(video: video)
                                .aspectRatio(1, contentMode: .fill)
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
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // thumbnail placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
            
            // video play icon
            Image(systemName: "play.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .shadow(radius: 2)
            
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
        .clipped()
    }
}

#Preview {
    PostsListView()
}
