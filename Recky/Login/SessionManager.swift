import Foundation
import FirebaseAuth
import Combine

class SessionManager: ObservableObject {
    @Published var user: User?
    @Published var isVerified: Bool = false

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        listen()
    }

    private func listen() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user

            guard let user = user else {
                self.isVerified = false
                return
            }

            // Always reload to get fresh verification status
            user.reload { _ in
                DispatchQueue.main.async {
                    self.isVerified = user.isEmailVerified
                }
            }
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
