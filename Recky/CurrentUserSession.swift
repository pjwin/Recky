import Foundation
import FirebaseAuth
import FirebaseFirestore

class CurrentUserSession: ObservableObject {
    static let shared = CurrentUserSession()

    @Published var uid: String = ""
    @Published var username: String = ""

    private init() {}

    func load() {
        guard let user = Auth.auth().currentUser else { return }
        uid = user.uid

        Firestore.firestore().collection("users").document(user.uid).getDocument { snapshot, error in
            if let name = snapshot?.get("username") as? String {
                DispatchQueue.main.async {
                    self.username = name
                }
            } else {
                print("Failed to fetch username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
