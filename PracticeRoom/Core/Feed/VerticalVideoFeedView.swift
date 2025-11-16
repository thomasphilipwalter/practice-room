//
//  VerticalVideoFeedView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/24/25.
//

import SwiftUI

struct VerticalVideoFeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    let isSearchShowing: Bool
    @State private var currentIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                            FeedVideoPlayerView(
                                video: video,
                                isCurrentVideo: index == currentIndex,
                                isSearchShowing: isSearchShowing
                            )
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .id(index)
                            .onAppear {
                                // Load more when approaching end (3 videos before end)
                                if index >= viewModel.videos.count - 3 {
                                    Task {
                                        await viewModel.loadMoreVideos()
                                    }
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 50)
                                    .onEnded { value in
                                        if value.translation.height < 0 && currentIndex < viewModel.videos.count - 1 {
                                            currentIndex += 1
                                            withAnimation {
                                                proxy.scrollTo(currentIndex, anchor: .top)
                                            }
                                        } else if value.translation.height > 0 && currentIndex > 0 {
                                            currentIndex -= 1
                                            withAnimation {
                                                proxy.scrollTo(currentIndex, anchor: .top)
                                            }
                                        }
                                    }
                            )
                        }
                        
                        // Loading indicator at bottom
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .scrollDisabled(true)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}
