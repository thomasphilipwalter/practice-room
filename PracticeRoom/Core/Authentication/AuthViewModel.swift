//
//  AuthViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/15/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var email = ""
    
    
    // SEND Magic Link
    func signInWithMagicLink(email: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await supabase.signInWithMagicLink(email: email)
            self.email = email
            successMessage = "Check your email for the magic link!"
        } catch {
            errorMessage = "Failed to send magic link: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    
    // HANDLE Magic Link
    func handleMagicLinkCallback(url: URL) async {
        do {
            try await supabase.handleMagicLinkCallback(url: url)
            successMessage = "Successfully signed in!"
            isAuthenticated = true
        } catch {
            errorMessage = "Failed to sign in. Please try again."
        }

    }
    
    // SIGN Out
    func signOut() async {
        do {
            try await supabase.signOut()
            isAuthenticated = false
            email = ""
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    
    // CHECK Auth State
    func checkAuthState() async {
        do {
            let _ = try await supabase.getCurrentSession()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }
    
}
