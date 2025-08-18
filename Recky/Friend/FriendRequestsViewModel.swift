import FirebaseAuth
import Foundation

@MainActor
class FriendRequestsViewModel: ObservableObject {
    @Published var requests: [(uid: String, username: String)] = []
    private let service = FriendService.shared

    func loadRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task { [weak self] in
            do {
                self?.requests = try await service.fetchFriendRequests(for: uid)
            } catch {
                self?.requests = []
            }
        }
    }

    func acceptRequest(uid: String, username: String, completion: @escaping () -> Void = {}) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        Task { [weak self] in
            do {
                try await service.acceptRequest(from: uid, otherUsername: username, currentUID: myUID)
                await MainActor.run { self?.loadRequests() }
                completion()
            } catch {
                // Ignore error for now
            }
        }
    }

    func ignoreRequest(uid: String, username: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        Task { [weak self] in
            do {
                try await service.ignoreRequest(from: uid, otherUsername: username, currentUID: myUID)
                await MainActor.run { self?.loadRequests() }
            } catch {
                // Ignore error for now
            }
        }
    }
}

