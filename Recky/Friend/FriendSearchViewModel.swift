import FirebaseAuth
import Foundation

@MainActor
class FriendSearchViewModel: ObservableObject {
    @Published var searchEmail: String = ""
    @Published var message: String = ""
    private let service = FriendService.shared

    func sendFriendRequestByEmail() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        service.sendFriendRequestByEmail(searchEmail, from: myUID) { [weak self] msg in
            self?.message = msg
        }
    }
}

