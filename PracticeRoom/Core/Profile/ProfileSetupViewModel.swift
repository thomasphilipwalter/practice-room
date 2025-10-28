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

struct ProfileSetupParams: Encodable {
    let id: String
    let username: String
    let fullName: String
    let instrument: String
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case instrument
        case avatarUrl = "avatar_url"
    }
}

@MainActor
class ProfileSetupViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var username = ""
    @Published var instrument = ""
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
    
    // Function saveProfile
    //      - save profile on setup
    func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await supabase.auth.session.user
            var avatarUrl: String? = nil
            
            // upload avatar if selected
            if let image = selectedImage {
                avatarUrl = try await supabase.uploadAvatar(image: image, userId: currentUser.id)
            }
            
            // Build profile data
            let params = ProfileSetupParams(
                id: currentUser.id.uuidString,
                username: username,
                fullName: fullName,
                instrument: instrument,
                avatarUrl: avatarUrl
            )
            
            try await supabase
                .from("profiles")
                .upsert(params)
                .execute()
                
        } catch {
            errorMessage = "Failed to save profile. Please try again."
        }
        
        isLoading = false
    }
}
