//
//  FriendsFeedView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/9/25.
//

import SwiftUI

struct FriendsFeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showSearchView = false
    
    var body: some View {
        ZStack {
            // Video feed
            if viewModel.isLoading {
                ProgressView("Loading videos...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if viewModel.videos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No videos from friends")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Follow other users to see their videos here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                VerticalVideoFeedView(videos: viewModel.videos)
                    .allowsHitTesting(true)  // Allow touches on video
            }
            
            // Search button overlay (top right) - This needs to be on top
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showSearchView = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                    .zIndex(1000)  // Ensure button is on top
                }
                Spacer()
            }
            .allowsHitTesting(true)  // Allow touches on overlay
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showSearchView) {
            SearchView()
        }
        .task {
            await viewModel.loadFollowingVideos()
        }
    }
}

#Preview {
    FriendsFeedView()
}
