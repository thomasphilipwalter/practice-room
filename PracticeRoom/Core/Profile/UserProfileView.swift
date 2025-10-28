//
//  UserProfileView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/23/25.
//

import SwiftUI

struct UserProfileView: View {
    let userId: UUID
    let isCurrentUser: Bool
    @StateObject private var viewModel = UserProfileViewModel()
    @StateObject private var followViewModel = FollowViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var selectedTab: Tab = .posts
    
    enum Tab: String, CaseIterable, Identifiable {
        case posts = "Posts"
        case pieces = "Pieces"
        var id: String { rawValue }
    }
    
    // Default initializer for viewing other users
    init(userId: UUID) {
        self.userId = userId
        self.isCurrentUser = false
    }
    
    // Initializer for viewing current user's profile
    init(userId: UUID, isCurrentUser: Bool) {
        self.userId = userId
        self.isCurrentUser = isCurrentUser
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    if let avatarUrl = viewModel.profile?.avatarUrl,
                       let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(radius: 2)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 80, height: 80)
                        }
                        .padding(.horizontal, 30)
                    } else {
                        Image("profile_placeholder")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(radius: 2)
                            .padding(.horizontal, 30)
                    }
                    
                    // Profile info (username, name, instrument, follower/following count)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.profile?.username ?? "")
                            .font(.headline)
                        Text(viewModel.profile?.fullName ?? "")
                            .font(.subheadline)
                        Text(viewModel.profile?.instrument ?? "")
                            .foregroundColor(.secondary)
                        
                        if let bio = viewModel.profile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.callout)
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                                .lineLimit(3)
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("\(followViewModel.followerCount)")
                                    .font(.headline)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("\(followViewModel.followingCount)")
                                    .font(.headline)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                        
                        // IF CURRENT USER: render update profile button, sign out button
                        if isCurrentUser {
                            NavigationLink(destination: UpdateProfileView(viewModel: viewModel, userId: userId)) {
                                Text("Update profile")
                            }
                            .padding(.top, 4)
                            Button("Sign out", role: .destructive) {
                                Task {
                                    await authViewModel.signOut()
                                }
                            }
                        // IF NOT CURRENT USER: render follow/unfollow button
                        } else {
                            Button(action: {
                                Task {
                                    if followViewModel.isFollowing {
                                        await followViewModel.unfollowUser(userId: userId)
                                    } else {
                                        await followViewModel.followUser(userId: userId)
                                    }
                                }
                            }) {
                                if followViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text(followViewModel.isFollowing ? "Unfollow" : "Follow")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(followViewModel.isFollowing ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(followViewModel.isLoading)
                            .padding(.top, 4)
                        }
                    }
                    Spacer()
                }
                .padding()
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Picker("Section", selection: $selectedTab) {
                        Text("Posts").tag(Tab.posts)
                        Text("Pieces").tag(Tab.pieces)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Group {
                        switch selectedTab {
                        case .posts:
                            PostsListView(userId: userId)
                        case .pieces:
                            PiecesListView()
                        }
                    }
                    .padding(.top, 12)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile(userId: userId)
            await followViewModel.loadFollowCounts(userId: userId)
            if !isCurrentUser {
                await followViewModel.checkIfFollowing(userId: userId)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: UUID())
    }
}
