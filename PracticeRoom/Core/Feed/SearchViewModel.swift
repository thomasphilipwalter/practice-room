//
//  SearchViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/23/25.
//
import Foundation
import Supabase
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func searchUsers() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            
            let results: [Profile] = try await supabase
                .from("profiles")
                .select()
                .ilike("username", pattern: "%\(searchQuery)%")
                .neq("id", value: currentUser.id)
                .execute()
                .value
            searchResults = results
        } catch {
            errorMessage = "Failed to search users: \(error.localizedDescription)"
            searchResults = []
        }
        
        isLoading = false
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        errorMessage = nil
    }
}
