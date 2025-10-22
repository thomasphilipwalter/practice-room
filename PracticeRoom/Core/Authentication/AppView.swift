//
//  AppView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import SwiftUI

// View: defines a visual element of screen. Can be made up of
struct AppView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        Group {
            switch viewModel.appState {
                case .loading:
                    ProgressView()
                case .unauthenticated:
                    AuthView()
                case .needsProfileSetup:
                    ProfileSetupView(onProfileSaved: {
                        Task {
                            await viewModel.refreshProfile()
                        }
                    })
                case .authenticated:
                    MainTabView()
            }
        }
    }
}

#Preview {
    AppView()
}
