//
//  SupabaseService.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import Foundation
import Supabase
import UIKit

let supabase = SupabaseClient(
    supabaseURL: Environment.supabaseURL,
    supabaseKey: Environment.supabaseKey
)

extension SupabaseClient {
    // Function: upload an image to storage and return the public URL
    func uploadAvatar(image: UIImage, userId: UUID) async throws -> String {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Generate unique filename
        let fileExtension = "jpg"
        let fileName = "\(userId.uuidString).\(fileExtension)"
        let filePath = "\(userId.uuidString)/\(fileName)"
        
        // Upload to storage
        try await self.storage
            .from("avatars")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true // allow overwriting existing data
                )
            )
        
        // Get public URL
        let publicURL = try self.storage
            .from("avatars")
            .getPublicURL(path: filePath)
        
        return publicURL.absoluteString
    }
}
