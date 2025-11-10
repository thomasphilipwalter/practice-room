//
//  AppView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import SwiftUI
import UIKit

struct AppView: View {
    // Import the view model
    @StateObject private var viewModel = AppViewModel()
    
    // Switch between four possible views:
    //  1. Loading
    //  2. Not authenticated
    //  3. Authenticated but needs profile setup
    //  4. Authenticated
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
