//
//  CommentFormView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 11/11/25.
//

import SwiftUI
import Supabase

struct CommentFormView: View {
    let videoId: UUID
    @ObservedObject var viewModel: CommentViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    @State private var goodThing = ""
    @State private var improvement = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("What was good?")
                        .font(.headline)
                    TextEditor(text: $goodThing)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(goodThing.isEmpty ? Color.red : Color.gray, lineWidth: 1)
                        )
                } header: {
                    Text("Required")
                } footer: {
                    Text("Please share what you liked about this performance")
                }
                
                Section {
                    Text("What could be improved?")
                        .font(.headline)
                    TextEditor(text: $improvement)
                        .frame(height: 100)
                } header: {
                    Text("Optional")
                } footer: {
                    Text("Share constructive feedback (optional)")
                }
                
                Section {
                    Button {
                        Task {
                            await submitComment()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Submit Comment")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(goodThing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add Comment")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func submitComment() async {
        isSubmitting = true
        do {
            let currentUser = try await supabase.getCurrentUser()
            await viewModel.addComment(
                videoId: videoId,
                userId: currentUser.id,
                goodThing: goodThing.trimmingCharacters(in: .whitespacesAndNewlines),
                improvement: improvement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : improvement.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            dismiss()
        } catch {
            // Error handled by viewModel
        }
        isSubmitting = false
    }
}
