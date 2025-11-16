import SwiftUI

struct FollowListView: View {
    enum Mode { case followers, following }

    let userId: UUID
    let mode: Mode

    @State private var usernames: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var title: String { mode == .followers ? "Followers" : "Following" }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if usernames.isEmpty {
                    Text("No \(title.lowercased()) yet.")
                        .foregroundColor(.secondary)
                } else {
                    List(usernames, id: \.self) { username in
                        Text(username)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await loadUsernames() }
    }

    private func loadUsernames() async {
        isLoading = true
        errorMessage = nil
        do {
            switch mode {
            case .followers:
                usernames = try await supabase.getFollowerUsernames(userId: userId)
            case .following:
                usernames = try await supabase.getFollowingUsernames(userId: userId)
            }
        } catch {
            errorMessage = "Failed to load \(title.lowercased()): \(error.localizedDescription)"
        }
        isLoading = false
    }
}
