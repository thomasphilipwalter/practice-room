//
//  AppViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/15/25.
//

import Supabase
import Foundation
import Combine

// NOTE: ViewModels should be performed on the main thread, pure UI Views need not
// ObservableObject: A type of obj. with a publisher that emits before the object has changed
@MainActor
class AppViewModel: ObservableObject {
    // Initial state loading. @Published is a property wrapper that notifies SwiftUI on any change
    // NOTE: .loading = shorthand for AppState.loading
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
            
            // Listen forever for auth changes
            Task {
                for await state in supabase.auth.authStateChanges { // NOTE: 'for await' used to iterate over an asynchronous stream
                    if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                        await updateAppState(session: state.session)
                    }
                }
            }
        }
    }
    
    // Function: updateAppState(session: Session?)
    // - Take supabase session as input
    // - Set app state appropiately
    func updateAppState(session: Session?) async {
        
        // CASE 1: unauthenticated —> if session is nil
        guard let session = session else {
            appState = .unauthenticated
            return
        }
        
        do {
            // query profile data model on session's user id
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: session.user.id)
                .single()
                .execute()
                .value
            
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
    
    // Function: refreshProfile()
    // - Checks supabase session
    // - Calls updateAppState to update state
    func refreshProfile() async {
        do {
            let session = try await supabase.auth.session
            await updateAppState(session: session)
        } catch {
            // TODO: Handle error appropriately
        }
    }
}

