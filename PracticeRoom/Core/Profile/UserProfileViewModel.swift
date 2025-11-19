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
    @Published var bio = ""
    
    // Fields for photo handling
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedPhotoData: Data?
    @Published var selectedImage: UIImage?
    
    func checkUsernameAvailability(excluding currentUserId: UUID) async -> Bool {
        do {
            return try await supabase.checkUsernameAvailability(
                username: username,
                excluding: currentUserId
            )
        } catch {
            return false
        }
    }
    
    func loadProfile(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedProfile = try await supabase.loadProfile(userId: userId)
            profile = fetchedProfile
            
            // Sync to editable fields
            username = fetchedProfile.username ?? ""
            fullName = fetchedProfile.fullName ?? ""
            instrument = fetchedProfile.instrument ?? ""
            bio = fetchedProfile.bio ?? ""
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
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
            // check if username is available (excluding current user)
            let isAvailable = await checkUsernameAvailability(excluding: userId)
            if !isAvailable {
                errorMessage = "Username '\(username)' is already taken. Please choose another."
                isLoading = false
                return
            }
            
            var avatarUrl: String? = profile?.avatarUrl
            if let image = selectedImage {
                // Compress image before upload
                guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                    errorMessage = "Failed to compress image"
                    isLoading = false
                    return
                }
                avatarUrl = try await supabase.uploadAvatar(imageData: imageData, userId: userId)
            }
            
            try await supabase.updateProfile(
                userId: userId,
                params: UpdateProfileParams(
                    username: username,
                    fullName: fullName,
                    instrument: instrument,
                    avatarUrl: avatarUrl,
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio
                )
            )
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
