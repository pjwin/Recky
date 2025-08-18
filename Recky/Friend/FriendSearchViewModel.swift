import FirebaseAuth
import Foundation

@MainActor
class FriendSearchViewModel: ObservableObject {
    @Published var searchEmail: String = ""
    @Published var message: String = ""
    private let service = FriendService.shared

    func sendFriendRequestByEmail() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        Task { [weak self] in
            do {
                let msg = try await service.sendFriendRequestByEmail(searchEmail, from: myUID)
                await MainActor.run { self?.message = msg }
            } catch {
                await MainActor.run { self?.message = "Failed to send request." }
            }
        }
    }
}

