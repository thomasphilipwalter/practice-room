//
//  ProfileView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let userId = viewModel.currentUserId {
                    UserProfileView(userId: userId, isCurrentUser: true)
                } else {
                    Text("Unable to load profile")
                        .foregroundColor(.red)
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                await viewModel.setCurrentUserId()
            }
        }
    }
}

#Preview {
    ProfileView()
}
