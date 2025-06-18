//
//  LoginView.swift
//  Recky
//
//  Created by Paul Winters on 6/17/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Recky")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
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
            }

            Button("Login") {
                login()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Sign Up") {
                signUp()
            }
            .foregroundColor(.blue)
        }
        .padding()
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
                    "friends": []
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
}
