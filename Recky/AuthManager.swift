import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import GoogleSignIn

class AuthManager {
    static let shared = AuthManager()

    private init() {}

    func login(
        email: String,
        password: String,
        completion: @escaping (String?) -> Void
    ) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if error == nil {
                CurrentUserSession.shared.load()
            }
            completion(error?.localizedDescription)
        }
    }

    func signUp(
        email: String,
        password: String,
        completion: @escaping (String?) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) {
            result,
            error in
            if let error = error {
                completion(error.localizedDescription)
                return
            }

            guard let user = result?.user else {
                completion("User creation failed.")
                return
            }

            let rawEmail = user.email ?? ""
            let username = rawEmail.components(separatedBy: "@").first ?? ""

            let userDoc: [String: Any] = [
                "email": rawEmail,
                "emailLowercase": rawEmail.lowercased(),
                "username": username,
                "friends": [],
                "friendRequests": [],
                "sentRequests": [],
            ]

            Firestore.firestore().collection("users").document(user.uid)
                .setData(userDoc) { error in
                    if let error = error {
                        print("Firestore error: \(error)")
                    }
                    CurrentUserSession.shared.load()
                }

            completion(nil)
        }
    }

    func handleGoogleSignIn(
        presenting: UIViewController,
        completion: @escaping (String?) -> Void
    ) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion("Missing Firebase client ID.")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID
        )

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) {
            result,
            error in
            guard let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                completion("Google Sign-In failed.")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    completion(error.localizedDescription)
                    return
                }

                guard let user = result?.user else { return }

                let userRef = Firestore.firestore().collection("users")
                    .document(user.uid)

                userRef.getDocument { document, _ in
                    guard document?.exists == false else {
                        CurrentUserSession.shared.load()
                        completion(nil)
                        return
                    }

                    let rawEmail = user.email ?? ""
                    let username =
                        rawEmail.components(separatedBy: "@").first ?? ""

                    let userDoc: [String: Any] = [
                        "email": rawEmail,
                        "emailLowercase": rawEmail.lowercased(),
                        "username": username,
                        "friends": [],
                        "friendRequests": [],
                        "sentRequests": [],
                    ]

                    userRef.setData(userDoc) { error in
                        if let error = error {
                            print("Error creating user doc: \(error)")
                        }
                        CurrentUserSession.shared.load()
                    }

                    completion(nil)
                }
            }
        }
    }

}
