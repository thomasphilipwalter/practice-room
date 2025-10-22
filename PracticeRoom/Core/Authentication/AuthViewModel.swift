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
    
    
    // Function signInWithMagicLink
    //      - call supabase function to send magic link to email
    func signInWithMagicLink(email: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await supabase.auth.signInWithOTP(email: email)
            self.email = email
            successMessage = "Check your email for the magic link!"
        } catch {
            errorMessage = "Failed to send magic link: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    
    // Function handleMagicLinkCallback
    //      - Log in from magic link callback
    func handleMagicLinkCallback(url: URL) async {
        do {
            try await supabase.auth.session(from: url)
            successMessage = "Successfully signed in!"
            isAuthenticated = true
        } catch {
            errorMessage = "Failed to sign in. Please try again."
        }

    }
    
    // Function signOut()
    //      - sign out using supabase function
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            email = ""
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    
    // Function checkAuthState()
    //      - check the auth state
    func checkAuthState() async {
        do {
            let _ = try await supabase.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }
    
}
