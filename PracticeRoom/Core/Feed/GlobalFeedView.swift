//
//  GlobalFeedView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/9/25.
//

import SwiftUI

struct GlobalFeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        ZStack {
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
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No videos yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Be the first to upload!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                VerticalVideoFeedView(videos: viewModel.videos, isSearchShowing: false)
            }
        }
        .task {
            await viewModel.loadAllVideos()
        }
    }
}

#Preview {
    GlobalFeedView()
}
