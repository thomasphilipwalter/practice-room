//
//  UploadView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/9/25.
//

import SwiftUI
import PhotosUI

struct UploadView: View {
    @StateObject private var videoViewModel = VideoViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Video") {
                    PhotosPicker(
                        selection: $videoViewModel.selectedVideo,
                        matching: .videos
                    ) {
                        HStack {
                            Image(systemName: "video.badge.plus")
                                .foregroundColor(.blue)
                            Text("Choose Video")
                        }
                    }
                    
                    // Show selection status below the picker
                    if videoViewModel.selectedVideo != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Video selected")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }
                
                Section("Video Details") {
                    TextField("Title", text: $videoViewModel.videoTitle)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optional)", text: $videoViewModel.videoDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section {
                    Button {
                        Task {
                            await videoViewModel.uploadVideo()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if videoViewModel.isUploading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(videoViewModel.isUploading ? "Uploading..." : "Upload Video")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(videoViewModel.selectedVideo == nil ||
                             videoViewModel.videoTitle.isEmpty ||
                             videoViewModel.isUploading)
                    
                    if let errorMessage = videoViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Upload Video")
        }
        .alert("Success!", isPresented: .constant(videoViewModel.successMessage != nil)) {
            Button("OK") {
                videoViewModel.successMessage = nil
            }
        } message: {
            Text("Video uploaded successfully!")
        }
    }
}

#Preview {
    UploadView()
}
