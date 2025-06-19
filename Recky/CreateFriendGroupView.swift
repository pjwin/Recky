//
//  CreateFriendGroupView.swift
//  Recky
//
//  Created by Paul Winters on 6/18/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct CreateFriendGroupView: View {
    @State private var groupName = ""
    @State private var friends: [(uid: String, username: String)] = []
    @State private var selectedUIDs: Set<String> = []

    var body: some View {
        VStack {
            TextField("Group Name", text: $groupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            List(friends, id: \.uid) { friend in
                HStack {
                    Text(friend.username)
                    Spacer()
                    if selectedUIDs.contains(friend.uid) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                selectedUIDs.remove(friend.uid)
                            }
                    } else {
                        Image(systemName: "circle")
                            .onTapGesture {
                                selectedUIDs.insert(friend.uid)
                            }
                    }
                }
            }

            Button("Create Group") {
                createGroup()
            }
            .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding()
        }
        .onAppear(perform: loadFriends)
        .navigationTitle("New Group")
    }

    func loadFriends() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(myUID).getDocument { doc, _ in
            guard let data = doc?.data(),
                let friendUIDs = data["friends"] as? [String]
            else { return }

            friends = []
            for uid in friendUIDs {
                db.collection("users").document(uid).getDocument { doc, _ in
                    if let username = doc?.get("username") as? String {
                        DispatchQueue.main.async {
                            friends.append((uid, username))
                        }
                    }
                }
            }
        }
    }

    func createGroup() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let groupData: [String: Any] = [
            "ownerId": myUID,
            "name": groupName,
            "memberUIDs": Array(selectedUIDs),
        ]

        db.collection("groups").addDocument(data: groupData) { error in
            if let error = error {
                print("Error creating group: \(error)")
            } else {
                print("Group created!")
            }
        }
    }
}
