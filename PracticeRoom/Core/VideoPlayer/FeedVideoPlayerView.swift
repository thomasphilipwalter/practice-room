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
    let isCurrentVideo: Bool
    let isSearchShowing: Bool
    @SwiftUI.Environment(\.scenePhase) private var scenePhase  // Add this
    
    var body: some View {
        ZStack {
            Color.black
            
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // Disable default controls
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
        }
        .onChange(of: isCurrentVideo) { newValue in
            if newValue && !isSearchShowing {
                player?.play()
                player?.seek(to: .zero)
            } else {
                player?.pause()
            }
        }
        .onChange(of: isSearchShowing) { newValue in
            if newValue {
                player?.pause()
            } else if isCurrentVideo {
                player?.play()
            }
        }
        .onChange(of: scenePhase) { newPhase in  // Pause when app goes to background or tab changes
            if newPhase != .active {
                player?.pause()
            } else if isCurrentVideo && newPhase == .active && !isSearchShowing {
                player?.play()
            }
        }
        .onAppear {
            setupPlayer()
            if isCurrentVideo && !isSearchShowing {
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil  // Properly release the player
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: video.videoUrl) else {
            print("❌ Invalid video URL: \(video.videoUrl)")
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
