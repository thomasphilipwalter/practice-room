//
//  CommentViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 11/11/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [CommentWithProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadComments(videoId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            self.comments = try await supabase.loadComments(videoId: videoId)
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func addComment(videoId: UUID, userId: UUID, goodThing: String, improvement: String?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.createComment(
                videoId: videoId,
                userId: userId,
                goodThing: goodThing,
                improvement: improvement
            )
            // Reload comments after adding
            await loadComments(videoId: videoId)
        } catch {
            errorMessage = "Failed to add comment: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
