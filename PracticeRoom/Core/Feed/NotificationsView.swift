//
//  NotificationsView.swift
//  PracticeRoom
//
//  Created by Thomas Walter
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.pendingRequests.isEmpty {
                    ProgressView()
                } else if viewModel.pendingRequests.isEmpty {
                    emptyState
                } else {
                    requestsList
                }
            }
            .navigationTitle("Follow Requests")
            .task {
                await viewModel.loadPendingFollowRequests()
            }
            .refreshable {
                await viewModel.loadPendingFollowRequests()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Follow Requests")
                .font(.title2)
                .fontWeight(.semibold)
            Text("You're all caught up!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var requestsList: some View {
        List {
            ForEach(viewModel.pendingRequests) { request in
                FollowRequestRowView(
                    request: request,
                    onAccept: {
                        Task {
                            await viewModel.acceptFollowRequest(request)
                        }
                    },
                    onReject: {
                        Task {
                            await viewModel.rejectFollowRequest(request)
                        }
                    }
                )
            }
        }
        .listStyle(.plain)
    }
}

struct FollowRequestRowView: View {
    let request: PendingFollowRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    
    private var profile: Profile {
        request.fromUserProfile
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Profile image
                AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(profile.username ?? "Someone") wants to follow you")
                        .font(.subheadline)
                    
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: onReject) {
                    Text("Reject")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: request.followRequest.createdAt, relativeTo: Date())
    }
}

