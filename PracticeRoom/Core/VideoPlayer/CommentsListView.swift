//
//  CommentsListView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 11/11/25.
//

import SwiftUI

struct CommentsListView: View {
    let videoId: UUID
    @StateObject private var viewModel = CommentViewModel()
    @State private var showCommentForm = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.comments.isEmpty {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.comments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No comments yet")
                            .foregroundColor(.secondary)
                        Text("Be the first to comment!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.comments) { commentWithProfile in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(commentWithProfile.profile.username ?? "Unknown")
                                        .font(.headline)
                                    Spacer()
                                    Text(commentWithProfile.comment.createdAt, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What was good:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(commentWithProfile.comment.goodThing)
                                }
                                .padding(.vertical, 4)
                                
                                if let improvement = commentWithProfile.comment.improvement {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("What could be improved:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(improvement)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCommentForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCommentForm) {
                CommentFormView(videoId: videoId, viewModel: viewModel)
            }
            .task {
                await viewModel.loadComments(videoId: videoId)
            }
        }
    }
}
