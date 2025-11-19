//
//  ProfileSetupViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/15/25.
//
import Supabase
import Foundation
import Combine
import UIKit
import PhotosUI
import _PhotosUI_SwiftUI

@MainActor
class ProfileSetupViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var username = ""
    @Published var instrument = ""
    @Published var bio = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Variables for profile/avatar upload
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedPhotoData: Data?
    @Published var selectedImage: UIImage?
    
    let instruments = ["Violin", "Viola", "Cello"]
    
    var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !instrument.isEmpty
    }
    
    func checkUsernameAvailability() async -> Bool {
        do {
            return try await supabase.checkUsernameAvailability(username: username)
        } catch {
            return false
        }
    }
    
    // Handle photo selection
    func handlePhotoSelection() async {
        guard let selectedPhotoItem else { return }
        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                selectedPhotoData = data
                if let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        } catch {
            errorMessage = "Failed to load image"
        }
    }
    
    // Save Profile on setup
    func saveProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            let isAvailable = await checkUsernameAvailability()
            if !isAvailable {
                errorMessage = "Username '\(username)' is already taken. Please choose another."
                isLoading = false
                return
            }
            let currentUser = try await supabase.getCurrentUser()
            
            var avatarUrl: String? = nil
            // upload avatar if selected
            if let image = selectedImage {
                // Compress image before upload
                guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                    errorMessage = "Failed to compress image"
                    isLoading = false
                    return
                }
                avatarUrl = try await supabase.uploadAvatar(imageData: imageData, userId: currentUser.id)
            }
            
            // handle bio
            let bioValue = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio
            // Build profile data
            let params = ProfileSetupParams(
                id: currentUser.id.uuidString,
                username: username,
                fullName: fullName,
                instrument: instrument,
                avatarUrl: avatarUrl,
                bio: bioValue
            )
            try await supabase.upsertProfile(params: params)
        } catch {
            errorMessage = "Failed to save profile. Please try again."
        }
        isLoading = false
    }
}
