//
//  ProfileSetupViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/15/25.
//
import Supabase
import Foundation
import Combine

@MainActor
class ProfileSetupViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var instrument = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let instruments = ["Violin", "Viola", "Cello"]
    
    var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !instrument.isEmpty
    }
    
    // Function saveProfile
    //      - save profile on setup
    func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            
            try await supabase
                .from("profiles")
                .upsert([
                    "id": currentUser.id.uuidString,
                    "full_name": fullName,
                    "instrument": instrument,
                ])
                .execute()
                
        } catch {
            errorMessage = "Failed to save profile. Please try again."
        }
        
        isLoading = false
    }
}
