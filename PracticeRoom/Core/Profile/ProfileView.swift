//
//  ProfileView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel() // for regular profile
    @StateObject private var videoViewModel = VideoViewModel() // for video upload
    @State private var selectedTab: Tab = .posts
    
    enum Tab: String, CaseIterable, Identifiable {
        case posts = "Posts"
        case pieces = "Pieces"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
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
                            
                        VStack(alignment: .leading, spacing: 8) {
                            // EVENTUALLY:
//                            Text("\(viewModel.username)")
//                                .font(.headline)
//                            Text("\(viewModel.fullName)")
//                                .font(.subheadline)
//                            Text("\(viewModel.instrument)")
//                                .foregroundColor(.secondary)
                            
//                             TESTING:
                            Text("thomas.walter")
                                .font(.headline)
                            Text("Thomas Walter")
                                .font(.subheadline)
                            Text("Cello")
                                .foregroundColor(.secondary)
                            
                            Button("Update profile") {
                                // TODO: Implement
                            }
                            Button("Sign out", role: .destructive) {
                                Task {
                                    await viewModel.signOut()
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    
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
                            PostsListView()
                        case .pieces:
                            PiecesListView()
                        }
                    }
                    .padding(.top, 12)
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}

#Preview {
    ProfileView()
}



// UPLOAD CODE

//                    Form {
                    //                                    Section {
                    //                                        TextField("Username", text: $viewModel.username)
                    //                                            .textContentType(.username)
                    //                                            .textInputAutocapitalization(.never)
                    //                                        TextField("Full name", text: $viewModel.fullName)
                    //                                            .textContentType(.name)
                    //                                        TextField("Instrument", text: $viewModel.instrument)
                    //                                            .textContentType(.none)
                    //                                            .textInputAutocapitalization(.words)
                    //                                            .autocorrectionDisabled()
                    //                                    }
                    //                                    Section {
                    //                                        Button("Update profile") {
                    //                                            Task {
                    //                                                await viewModel.updateProfile()
                    //                                            }
                    //                                        }
                    //                                        .bold()
                    //                                        .disabled(viewModel.isLoading) // TODO: check this might be why buttons are buggy
                    //
                    //                                        if viewModel.isLoading {
                    //                                            ProgressView() // SWIFT UI native function
                    //                                        }
                    //
                    //                                        // Render error if exists
                    //                                        if let errorMessage = viewModel.errorMessage {
                    //                                            Text(errorMessage)
                    //                                                .foregroundColor(.red)
                    //                                        }
                    //                                    }
                    //                                }
                    //                                .frame(height: 300)
                    
