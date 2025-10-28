//
//  UpdateProfileView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/23/25.
//
// UpdateProfileView.swift
import SwiftUI
import PhotosUI

struct UpdateProfileView: View {
    @StateObject var viewModel: UserProfileViewModel
    let userId: UUID
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            // add photo section
            Section {
                HStack {
                    Spacer()
                    
                    // Capture values before PhotosPicker closure
                    let selectedImage = viewModel.selectedImage
                    let avatarUrl = viewModel.profile?.avatarUrl
                    
                    PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else if let avatarUrl = avatarUrl,
                                  let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .onChange(of: viewModel.selectedPhotoItem) { newValue in
                        Task { @MainActor in
                            await viewModel.handlePhotoSelection()
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } header: {
                Text("Profile Photo")
            }
            
            Section {
                TextField("Username", text: $viewModel.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                TextField("Full name", text: $viewModel.fullName)
                    .textContentType(.name)
                TextField("Instrument", text: $viewModel.instrument)
                    .textContentType(.none)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $viewModel.bio)
                        .frame(height: 100)
                    
                    Text("\(viewModel.bio.count)/200 characters")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .onChange(of: viewModel.bio) { newValue in
                    if newValue.count > 200 {
                        viewModel.bio = String(newValue.prefix(200))
                    }
                }
            } header: {
                Text("Bio (Optional)")
            }
            Section {
                Button("Save changes") {
                    Task {
                        await viewModel.updateProfile(userId: userId)
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }
                .bold()
                .disabled(viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                }

                // Render error if exists
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Update Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        UpdateProfileView(viewModel: UserProfileViewModel(), userId: UUID())
    }
}
