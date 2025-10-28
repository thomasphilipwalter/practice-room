//
//  UserProfileViewModel.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/23/25.
//

import Foundation
import Supabase
import Combine
import UIKit
import PhotosUI
import _PhotosUI_SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Editable fields for updating profile
    @Published var username = ""
    @Published var fullName = ""
    @Published var instrument = ""
    
    // Fields for photo handling
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedPhotoData: Data?
    @Published var selectedImage: UIImage?
    
    func loadProfile(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProfile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            profile = fetchedProfile
            // Sync to editable fields
            username = fetchedProfile.username ?? ""
            fullName = fetchedProfile.fullName ?? ""
            instrument = fetchedProfile.instrument ?? ""
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // handle photo selection
    func handlePhotoSelection() async {
        guard let selectedPhotoItem else {
            return
        }
        
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
    
    func updateProfile(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var avatarUrl: String? = profile?.avatarUrl
            
            // Upload new avatar if selected
            if let image = selectedImage {
                avatarUrl = try await supabase.uploadAvatar(image: image, userId: userId)
            }
            
            try await supabase
                .from("profiles")
                .update(
                    UpdateProfileParams(
                        username: username,
                        fullName: fullName,
                        instrument: instrument,
                        avatarUrl: avatarUrl
                    )
                )
                .eq("id", value: userId)
                .execute()
            
            // Reload profile after successful update
            await loadProfile(userId: userId)
            
            // clear selection after successful upload
            selectedPhotoItem = nil
            selectedImage = nil
            selectedPhotoData = nil
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
