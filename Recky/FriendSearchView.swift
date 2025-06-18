//
//  FriendSearchView.swift
//  Recky
//
//  Created by Paul Winters on 6/18/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendSearchView: View {
    @State private var searchUsername = ""
    @State private var foundUser: (uid: String, username: String)? = nil
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Search by username", text: $searchUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Button("Search") {
                searchUser()
            }

            if let user = foundUser {
                Text("Found: \(user.username)")
                Button("Send Friend Request") {
                    sendFriendRequest(to: user.uid)
                }
                .foregroundColor(.blue)
            }

            if !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }

    func searchUser() {
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isEqualTo: searchUsername)
            .getDocuments { snapshot, error in
                if let error = error {
                    message = "Error: \(error.localizedDescription)"
                    return
                }
                guard let doc = snapshot?.documents.first else {
                    message = "User not found"
                    return
                }
                let uid = doc.documentID
                let username = doc.get("username") as? String ?? "Unknown"
                foundUser = (uid, username)
                message = ""
            }
    }

    func sendFriendRequest(to targetUID: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let myRef = db.collection("users").document(myUID)
        let targetRef = db.collection("users").document(targetUID)

        myRef.updateData([
            "sentRequests": FieldValue.arrayUnion([targetUID])
        ])

        targetRef.updateData([
            "friendRequests": FieldValue.arrayUnion([myUID])
        ])

        message = "Request sent!"
    }
}
