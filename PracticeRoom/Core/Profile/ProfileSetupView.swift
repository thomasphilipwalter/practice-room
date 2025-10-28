//
//  ProfileSetupView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/9/25.
//

import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    var onProfileSaved: () -> Void = {} // Hold callback function
    @StateObject private var viewModel = ProfileSetupViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Welcome to PracticeRoom!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Set up your profile")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
                
                // Photo picker
                VStack(spacing: 12) {
                    // Capture value before PhotosPicker closure
                    let selectedImage = viewModel.selectedImage
                    
                    PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 100, height: 100)
                                
                                VStack(spacing: 4) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Add Photo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedPhotoItem) { newValue in
                        Task { @MainActor in
                            await viewModel.handlePhotoSelection()
                        }
                    }
                    
                    if viewModel.selectedImage != nil {
                        Text("Tap to change photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                // Form for profile setup
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Full Name", text: $viewModel.fullName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Username", text: $viewModel.username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Instrument")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Menu {
                            ForEach(viewModel.instruments, id: \.self) { inst in
                                Button(inst) {
                                    viewModel.instrument = inst
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.instrument.isEmpty ? "Select Instrument" : viewModel.instrument)
                                    .foregroundColor(viewModel.instrument.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                
                // save profile
                Button(action: {
                    Task {
                        await viewModel.saveProfile()
                        if viewModel.errorMessage == nil {
                            onProfileSaved()
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!viewModel.isValid || viewModel.isLoading)
                .padding(.top, 8)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
    
#Preview {
    ProfileSetupView()
}
