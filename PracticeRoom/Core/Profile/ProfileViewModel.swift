//
//  ProfileViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/15/25.
//
import Foundation
import Supabase
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username = ""
    @Published var fullName = ""
    @Published var instrument = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value
            
            self.username = profile.username ?? ""
            self.fullName = profile.fullName ?? ""
            self.instrument = profile.instrument ?? ""
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            
            try await supabase
                .from("profiles")
                .update(
                    UpdateProfileParams(
                        username: username,
                        fullName: fullName,
                        instrument: instrument
                    )
                )
                .eq("id", value: currentUser.id)
                .execute()
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
}
