import Foundation
import Supabase
import Combine

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var pendingRequests: [PendingFollowRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Load pending follow requests
    func loadPendingFollowRequests() async {
        isLoading = true
        errorMessage = nil
        do {
            let currentUser = try await supabase.getCurrentUser()
            let requests = try await supabase.getPendingFollowRequests(userId: currentUser.id)
            
            // Fetch profiles for all follower users
            var requestsWithProfiles: [PendingFollowRequest] = []
            for request in requests {
                do {
                    let profile = try await supabase.loadProfile(userId: request.followerId)
                    requestsWithProfiles.append(
                        PendingFollowRequest(
                            id: request.id,
                            followRequest: request,
                            fromUserProfile: profile
                        )
                    )
                } catch {
                    print("Failed to load profile for follow request: \(error)")
                }
            }
            self.pendingRequests = requestsWithProfiles
        } catch {
            errorMessage = "Failed to load follow requests: \(error.localizedDescription)"
            print("Error loading follow requests: \(error)")
        }
        isLoading = false
    }
    
    // Accept follow request
    func acceptFollowRequest(_ request: PendingFollowRequest) async {
        do {
            try await supabase.acceptFollowRequest(followId: request.id)
            // Remove from local list immediately for responsive UI
            pendingRequests.removeAll { $0.id == request.id }
            // Optionally reload to be sure
            await loadPendingFollowRequests()
        } catch {
            errorMessage = "Failed to accept follow request: \(error.localizedDescription)"
            print("Accept error: \(error)")
        }
    }
    
    // Reject follow request
    func rejectFollowRequest(_ request: PendingFollowRequest) async {
        do {
            try await supabase.rejectFollowRequest(followId: request.id)
            // Remove from local list immediately for responsive UI
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = "Failed to reject follow request: \(error.localizedDescription)"
            print("Reject error: \(error)")
        }
    }
    
    var unreadCount: Int {
        pendingRequests.count
    }
}
