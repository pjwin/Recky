//
//  FriendsListView.swift
//  Recky
//
//  Created by Paul Winters on 6/18/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendsListView: View {
    @State private var friends: [(uid: String, username: String)] = []
    @State private var showAlert = false
    @State private var friendToRemove: (uid: String, username: String)?
    @State private var groupedFriends: [String: [(uid: String, username: String)]] = [:]
    @State private var allFriendUIDs: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Friends")
                .font(.title2)
                .bold()

            if groupedFriends.isEmpty {
                Text("No friends yet 😢")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(groupedFriends.keys.sorted(), id: \.self) { groupName in
                        Section(header: Text(groupName)) {
                            ForEach(groupedFriends[groupName] ?? [], id: \.uid) { friend in
                                HStack {
                                    Text(friend.username)
                                    Spacer()
                                    Button("Remove") {
                                        removeFriend(uid: friend.uid)
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear(perform: loadGroupedFriends)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Remove Friend"),
                message: Text("Are you sure you want to remove \(friendToRemove?.username ?? "this friend")?"),
                primaryButton: .destructive(Text("Remove")) {
                    if let uid = friendToRemove?.uid {
                        removeFriend(uid: uid)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    func loadGroupedFriends() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(myUID).getDocument { doc, _ in
            guard let data = doc?.data(), let friendUIDs = data["friends"] as? [String] else { return }

            self.allFriendUIDs = friendUIDs

            // Load user groups
            db.collection("groups").whereField("ownerId", isEqualTo: myUID).getDocuments { snapshot, _ in
                var usedUIDs = Set<String>()
                var grouped: [String: [(uid: String, username: String)]] = [:]

                for doc in snapshot?.documents ?? [] {
                    let groupName = doc.get("name") as? String ?? "Unnamed Group"
                    let members = doc.get("memberUIDs") as? [String] ?? []

                    for uid in members where friendUIDs.contains(uid) {
                        usedUIDs.insert(uid)
                        fetchFriend(uid: uid) { username in
                            grouped[groupName, default: []].append((uid, username))
                        }
                    }
                }

                // Ungrouped
                let ungrouped = friendUIDs.filter { !usedUIDs.contains($0) }
                for uid in ungrouped {
                    fetchFriend(uid: uid) { username in
                        grouped["Ungrouped", default: []].append((uid, username))
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.groupedFriends = grouped
                }
            }
        }
    }
    
    func fetchFriend(uid: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, _ in
            let username = doc?.get("username") as? String ?? "Unknown"
            completion(username)
        }
    }

    func removeFriend(uid otherUID: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let myRef = db.collection("users").document(myUID)
        let otherRef = db.collection("users").document(otherUID)

        myRef.updateData([
            "friends": FieldValue.arrayRemove([otherUID])
        ])
        otherRef.updateData([
            "friends": FieldValue.arrayRemove([myUID])
        ])

        // Optimistically update local state
        self.friends.removeAll { $0.uid == otherUID }
    }
}

