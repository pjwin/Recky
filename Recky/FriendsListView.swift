//
//  FriendsListView.swift
//  Recky
//
//  Created by Paul Winters on 6/18/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendsListView: View {
    @State private var friends: [(uid: String, username: String)] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Friends")
                .font(.title2)
                .padding(.bottom)

            if friends.isEmpty {
                Text("No friends yet 😢")
                    .foregroundColor(.gray)
            } else {
                List(friends, id: \.uid) { friend in
                    Text(friend.username)
                }
            }
        }
        .padding()
        .onAppear(perform: loadFriends)
    }

    func loadFriends() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(myUID).getDocument { doc, error in
            guard let data = doc?.data(),
                let friendUIDs = data["friends"] as? [String]
            else { return }

            self.friends = []

            for uid in friendUIDs {
                db.collection("users").document(uid).getDocument { doc, _ in
                    if let username = doc?.get("username") as? String {
                        DispatchQueue.main.async {
                            self.friends.append((uid, username))
                        }
                    }
                }
            }
        }
    }
}
