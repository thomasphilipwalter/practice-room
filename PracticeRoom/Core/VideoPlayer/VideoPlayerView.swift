//
//  VideoPlayerView.swift
//  PracticeRoom
//
//  Created by Thomas Walter
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?
    @State private var showComments = false
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView("Loading video...")
                    .tint(.white)
            }
            
            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
                
                // Comment button at bottom
                HStack {
                    Spacer()
                    Button {
                        showComments = true
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left")
                            Text("Comments")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsListView(videoId: video.id)
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .navigationTitle(video.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func setupPlayer() {
        guard let url = URL(string: video.videoUrl) else {
            return
        }
        
        player = AVPlayer(url: url)
        player?.play()
    }
}

#Preview {
    VideoPlayerView(video: Video(
        id: UUID(),
        title: "Sample Video",
        description: "This is a sample",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        userId: UUID(),
        createdAt: Date(),
        updatedAt: nil
    ))
}
