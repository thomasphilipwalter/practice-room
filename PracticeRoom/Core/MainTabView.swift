//
//  MainTabView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/9/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            GlobalFeedView()
                .tabItem() {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)
            
            FriendsFeedView()
                .tabItem() {
                    Label("Friends", systemImage: "heart.fill")
                }
                .tag(1)
            
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}
