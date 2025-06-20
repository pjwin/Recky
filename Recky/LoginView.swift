import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(.top, 40)

            Text("Welcome to Recky")
                .font(.title)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: login) {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            VStack(spacing: 16) {
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Button(action: handleGoogleSignIn) {
                    HStack {
                        Image("GoogleLogo")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Sign in with Google")
                            .foregroundColor(.black)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                
                Spacer().frame(height: 12)

                Button("Sign Up with Email", action: signUp)
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    func login() {
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signUp() {
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                let db = Firestore.firestore()
                let userDoc: [String: Any] = [
                    "email": user.email ?? "",
                    "username": user.email?.components(separatedBy: "@").first ?? "",
                    "friends": [],
                    "friendRequests": [],
                    "sentRequests": []
                ]

                db.collection("users").document(user.uid).setData(userDoc) { error in
                    if let error = error {
                        print("Failed to create user doc: \(error)")
                    } else {
                        print("User document created!")
                    }
                }
            }
        }
    }

    private func handleGoogleSignIn() {
        let currentSession = session

        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root VC")
            return
        }

        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Missing Google authentication")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase sign-in with Google failed: \(error.localizedDescription)")
                } else if let user = result?.user {
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(user.uid)

                    userRef.getDocument { document, error in
                        guard document?.exists == false else { return }

                        let userDoc: [String: Any] = [
                            "email": user.email ?? "",
                            "username": user.email?.components(separatedBy: "@").first ?? "",
                            "friends": [],
                            "friendRequests": [],
                            "sentRequests": []
                        ]

                        userRef.setData(userDoc) { error in
                            if let error = error {
                                print("Failed to create user doc: \(error)")
                            } else {
                                print("User document created!")
                            }
                        }
                    }
                }
            }
        }
    }
}
