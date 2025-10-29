//
//  AppViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/15/25.
//

import Supabase
import Foundation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var appState: AppState = .loading
    
    enum AppState {
        case loading
        case unauthenticated
        case needsProfileSetup
        case authenticated
    }
    
    init() {
        Task {
            await refreshProfile()
            
            Task {
                for await state in supabase.auth.authStateChanges { // NOTE: 'for await' used to iterate over an asynchronous stream
                    if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                        await updateAppState(session: state.session)
                    }
                }
            }
        }
    }

    func updateAppState(session: Session?) async {
        // CASE 1: unauthenticated —> if session is nil
        guard let session = session else {
            appState = .unauthenticated
            return
        }
    
        do {
            // query profile data model on session's user id
            let profile = try await supabase.loadProfile(userId: session.user.id)

            // CASE 2: authenticated and profile complete —> if fullName, instrument, username setup
            if let fullName = profile.fullName, !fullName.isEmpty,
               let instrument = profile.instrument, !instrument.isEmpty,
               let username = profile.username, !username.isEmpty {
                appState = .authenticated
            // CASE 3: needsProfileSetup –> if one of fullName, instrument, username not filled out
            } else {
                appState = .needsProfileSetup
            }
        } catch {
            appState = .needsProfileSetup
        }
    }
    
    func refreshProfile() async {
        do {
            let session = try await supabase.getCurrentSession()
            await updateAppState(session: session)
        } catch {
            await updateAppState(session: nil)
        }
    }
}

