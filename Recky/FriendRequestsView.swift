//
//  FriendRequestsView.swift
//  Recky
//
//  Created by Paul Winters on 6/18/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendRequestsView: View {
    @State private var requests: [(uid: String, username: String)] = []
    
    var onFriendAccepted: () -> Void = {}

    var body: some View {
        VStack {
            List(requests, id: \.uid) { request in
                HStack {
                    Text(request.username)
                    Spacer()
                    Button("Accept") {
                        acceptRequest(from: request.uid)
                        onFriendAccepted()
                    }
                }
            }
        }
        .onAppear(perform: loadRequests)
    }

    func loadRequests() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(myUID).getDocument { doc, error in
            guard let data = doc?.data(), let ids = data["friendRequests"] as? [String] else { return }
            self.requests = []

            for uid in ids {
                db.collection("users").document(uid).getDocument { doc, _ in
                    if let username = doc?.get("username") as? String {
                        self.requests.append((uid, username))
                    }
                }
            }
        }
    }

    func acceptRequest(from otherUID: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let myRef = db.collection("users").document(myUID)
        let otherRef = db.collection("users").document(otherUID)

        myRef.updateData([
            "friendRequests": FieldValue.arrayRemove([otherUID]),
            "friends": FieldValue.arrayUnion([otherUID])
        ])

        otherRef.updateData([
            "sentRequests": FieldValue.arrayRemove([myUID]),
            "friends": FieldValue.arrayUnion([myUID])
        ])

        // Optional: refresh requests list
        loadRequests()
    }
}
