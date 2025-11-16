//
//  PostsListView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/20/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cacheDirectory: URL
    
    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cacheDir.appendingPathComponent("VideoThumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cachePath(for videoId: UUID) -> URL {
        return cacheDirectory.appendingPathComponent("\(videoId.uuidString).jpg")
    }
    
    func getCachedThumbnail(for videoId: UUID) -> UIImage? {
        let path = cachePath(for: videoId)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }
    
    func saveThumbnail(_ image: UIImage, for videoId: UUID) {
        let path = cachePath(for: videoId)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: path)
        }
    }
}

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
            if let thumbnailImage = thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            
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
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // Check disk cache first
        if let cached = ThumbnailCache.shared.getCachedThumbnail(for: video.id) {
            await MainActor.run {
                self.thumbnailImage = cached
                self.isLoading = false
            }
            return
        }
        
        // Generate if not cached
        await generateThumbnail()
    }
    
    private func generateThumbnail() async {
        guard let url = URL(string: video.videoUrl) else {
            await MainActor.run { isLoading = false }
            return
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try await imageGenerator.image(at: CMTime.zero).image
            let uiImage = UIImage(cgImage: cgImage)
            
            await MainActor.run {
                self.thumbnailImage = uiImage
                self.isLoading = false
            }
            
            // Save to disk cache
            ThumbnailCache.shared.saveThumbnail(uiImage, for: video.id)
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    PostsListView()
}
