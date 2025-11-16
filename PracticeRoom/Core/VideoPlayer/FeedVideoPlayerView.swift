//
//  FeedVideoPlayerView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/24/25.
//

import SwiftUI
import AVKit

struct FeedVideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?
    @State private var showComments = false
    @State private var isPlaying = false
    let isCurrentVideo: Bool
    let isSearchShowing: Bool
    @SwiftUI.Environment(\.scenePhase) private var scenePhase  // Add this
    
    var body: some View {
        ZStack {
            Color.black
            
            if let player = player {
                VideoPlayer(player: player)
                    .overlay(
                        Color.clear
                            .contentShape(Rectangle())       // makes entire view tappable
                            .onTapGesture { togglePlayback() }
                    )
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // Video info overlay at bottom
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        if let description = video.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showComments = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                            Text("Comments")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 24)
                    .padding(.trailing, 20)
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsListView(videoId: video.id)
        }
        .onChange(of: isCurrentVideo) { newValue in
            if newValue && !isSearchShowing {
                player?.seek(to: .zero)
                player?.play()
                isPlaying = true
            } else {
                player?.pause()
                isPlaying = false
            }
        }
        .onChange(of: isSearchShowing) { newValue in
            if newValue {
                player?.pause()
                isPlaying = false
            } else if isCurrentVideo {
                player?.play()
                isPlaying = true
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase != .active {
                player?.pause()
                isPlaying = false
            } else if isCurrentVideo && !isSearchShowing {
                player?.play()
                isPlaying = true
            }
        }
        .onAppear {
            setupPlayer()
            if isCurrentVideo && !isSearchShowing {
                player?.play()
                isPlaying = true
            }
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
            player = nil
        }
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func setupPlayer() {
        guard let url = URL(string: video.videoUrl) else {
            print("Invalid video URL: \(video.videoUrl)")
            return
        }
        
        player = AVPlayer(url: url)
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}
