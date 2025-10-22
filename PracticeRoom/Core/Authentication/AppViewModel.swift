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
                for await state in supabase.auth.authStateChanges {
                    if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                        await updateAppState(session: state.session)
                    }
                }
            }
        }
    }
    
//    private func setupAuthListener() async {
//        await refreshProfile()
//        
//        // Listen to changes in authentication state
//        // Types
//        //      - INITIAL_SESSION
//        //      - SIGNED_IN
//        //      - SIGNED_OUT
//        //      - TOKEN_REFRESHED
//        //      - USER_UPDATED
//        //      - PASSWORD_RECOVERY
//        for await state in supabase.auth.authStateChanges {
//            if [.initialSession, .signedIn, .signedOut].contains(state.event) {
//                await updateAppState(session: state.session)
//            }
//        }
//    }
    
    // Function updateAppState:
    //      - Take a state.session (nil if signed out) and decide which AppState to present
    func updateAppState(session: Session?) async {
        
        // guard: only assign if not nil
        guard let session = session else {
            // if nil, signed out —> set unauthenticated
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
            
            // if name, instrument, username empty, needs profile setup
            if let fullName = profile.fullName, !fullName.isEmpty,
               let instrument = profile.instrument, !instrument.isEmpty,
               let username = profile.username, !username.isEmpty {
                appState = .authenticated
            } else {
                appState = .needsProfileSetup
            }
        } catch {
            appState = .needsProfileSetup
        }
    }
    
    func refreshProfile() async {
        do {
            let session = try await supabase.auth.session
            await updateAppState(session: session)
        } catch {
            // Handle error in session update
        }
    }
}

