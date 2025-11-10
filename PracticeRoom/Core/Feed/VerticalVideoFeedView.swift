//
//  VerticalVideoFeedView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/24/25.
//

import SwiftUI

struct VerticalVideoFeedView: View {
    let videos: [Video]
    let isSearchShowing: Bool
    @State private var currentIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
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
                            .gesture(
                                DragGesture(minimumDistance: 50)
                                    .onEnded { value in
                                        if value.translation.height < 0 && currentIndex < videos.count - 1 {
                                            // Swipe up - next video
                                            currentIndex += 1
                                            withAnimation {
                                                proxy.scrollTo(currentIndex, anchor: .top)
                                            }
                                        } else if value.translation.height > 0 && currentIndex > 0 {
                                            // Swipe down - previous video
                                            currentIndex -= 1
                                            withAnimation {
                                                proxy.scrollTo(currentIndex, anchor: .top)
                                            }
                                        }
                                    }
                            )
                        }
                    }
                }
                .scrollDisabled(true) // Disable default scrolling
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}
