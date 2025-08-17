import FirebaseAuth
import Foundation

@MainActor
class FriendRequestsViewModel: ObservableObject {
    @Published var requests: [(uid: String, username: String)] = []
    private let service = FriendService.shared

    func loadRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        service.fetchFriendRequests(for: uid) { [weak self] reqs in
            self?.requests = reqs
        }
    }

    func acceptRequest(from uid: String, completion: @escaping () -> Void = {}) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        service.acceptRequest(from: uid, currentUID: myUID) { [weak self] in
            self?.loadRequests()
            completion()
        }
    }

    func ignoreRequest(from uid: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        service.ignoreRequest(from: uid, currentUID: myUID) { [weak self] in
            self?.loadRequests()
        }
    }
}

