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
    
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    
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
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        if let avatarUrl = viewModel.profile?.avatarUrl,
                           let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    )
                                    .shadow(radius: 2)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            }
                        } else {
                            Image("profile_placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(radius: 2)
                        }
                        
                        // Profile info (username, name, instrument, follower/following count)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.profile?.username ?? "")
                                .font(.custom("Merriweather-Regular", size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text(viewModel.profile?.fullName ?? "")
                                .font(.custom("Merriweather-Regular", size: 15))
                                .foregroundColor(.black)
                            Text(viewModel.profile?.instrument ?? "")
                                .font(.custom("Merriweather-Regular", size: 13))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let bio = viewModel.profile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.custom("Merriweather-Regular", size: 14))
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                            
                        HStack(spacing: 16) {
                            Button {
                                showFollowersList = true
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("\(followViewModel.followerCount)")
                                        .font(.custom("Merriweather-Regular", size: 18))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    Text("Followers")
                                        .font(.custom("Merriweather-Regular", size: 12))
                                        .foregroundColor(.black)
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                showFollowingList = true
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("\(followViewModel.followingCount)")
                                        .font(.custom("Merriweather-Regular", size: 18))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    Text("Following")
                                        .font(.custom("Merriweather-Regular", size: 12))
                                        .foregroundColor(.black)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                            
                        // IF CURRENT USER: render update profile button, sign out button
                        if isCurrentUser {
                            NavigationLink(destination: UpdateProfileView(viewModel: viewModel, userId: userId)) {
                                Text("Update profile")
                                    .font(.custom("Merriweather-Regular", size: 15))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(red: 48/255, green: 37/255, blue: 120/255))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)

                            Button(action: {
                                Task {
                                    await authViewModel.signOut()
                                }
                            }) {
                                Text("Sign out")
                                    .font(.custom("Merriweather-Regular", size: 15))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(red: 201/255, green: 8/255, blue: 31/255))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        // IF NOT CURRENT USER: render follow/unfollow button
                        } else {
                            followButton
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.custom("Merriweather-Regular", size: 14))
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        PostsListView(userId: userId)
                            .padding(.top, 12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFollowersList) {
                FollowListView(userId: userId, mode: .followers)
            }
            .sheet(isPresented: $showFollowingList) {
                FollowListView(userId: userId, mode: .following)
            }
            .task {
                await viewModel.loadProfile(userId: userId)
                await followViewModel.loadFollowCounts(userId: userId)
                if !isCurrentUser {
                    await followViewModel.checkFollowStatus(userId: userId)
                }
            }
            .onAppear() {
                Task {
                    await followViewModel.loadFollowCounts(userId: userId)
                }
            }
        }
    }
    
    // Follow button with different states
    private var followButton: some View {
        Button(action: {
            Task {
                if followViewModel.isFollowing || followViewModel.isPending {
                    await followViewModel.unfollowUser(userId: userId)
                } else {
                    await followViewModel.sendFollowRequest(userId: userId)
                }
            }
        }) {
            if followViewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
            } else {
                HStack {
                    Text(followButtonText)
                        .font(.custom("Merriweather-Regular", size: 15))
                        .fontWeight(.semibold)
                    
                    if followViewModel.isPending {
                        Image(systemName: "clock")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(followButtonColor)
        .foregroundColor(.white)
        .cornerRadius(8)
        .disabled(followViewModel.isLoading)
        .padding(.top, 4)
    }
    
    private var followButtonText: String {
        if followViewModel.isFollowing {
            return "Following"
        } else if followViewModel.isPending {
            return "Requested"
        } else {
            return "Follow"
        }
    }
    
    private var followButtonColor: Color {
        if followViewModel.isFollowing {
            return .gray
        } else if followViewModel.isPending {
            return .orange
        } else {
            return Color(red: 48/255, green: 37/255, blue: 120/255)
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: UUID())
    }
}
