//
//  MainTabView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/9/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var notificationsViewModel = NotificationsViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            GlobalFeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)
            
            FriendsFeedView()
                .tabItem {
                    Label("Friends", systemImage: "heart.fill")
                }
                .tag(1)
            
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Pass the same viewModel so the badge and the list stay in sync
            NotificationsView(viewModel: notificationsViewModel)
                .tabItem {
                    Label("Requests", systemImage: "bell.fill")
                }
                .badge(notificationsViewModel.unreadCount)
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color(red: 122/255, green: 54/255, blue: 17/255), for: .tabBar)
        // Initial fetch for the badge
        .task {
            await notificationsViewModel.loadPendingFollowRequests()
        }
        // Refresh when user switches to the notifications tab
        .onChange(of: selectedTab) { newValue in
            if newValue == 3 {
                Task { await notificationsViewModel.loadPendingFollowRequests() }
            }
        }
    }
}


#Preview {
    MainTabView()
}
