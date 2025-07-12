import Foundation
import FirebaseAuth
import Combine

class SessionManager: ObservableObject {
    @Published var user: User?

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        listen()
    }

    private func listen() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
