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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: UUID?
    
    // Function to set currentUserId
    func setCurrentUserId() async {
        guard currentUserId == nil else { return } // don't reload if already loaded
        isLoading = true
        errorMessage = nil
        do {
            let user = try await supabase.getCurrentUser()
            currentUserId = user.id
        } catch {
            errorMessage = "Failed to get current user id: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
