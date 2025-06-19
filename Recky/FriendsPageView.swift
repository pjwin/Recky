//
//  FriendsPageView.swift
//  Recky
//
//  Created by Paul Winters on 6/18/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendsPageView: View {
    @State private var friends: [(uid: String, username: String)] = []
    @State private var requestCount = 0
    @State private var showRequests = false
    @State private var showFriendSearch = false
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: { showRequests = true }) {
                    HStack {
                        Label("Requests", systemImage: "person.crop.circle.badge.questionmark")
                            .frame(maxWidth: .infinity)
                        if requestCount > 0 {
                            Text("(\(requestCount))")
                                .foregroundColor(.red)
                        }
                    }
                }

                Button(action: { showFriendSearch = true }) {
                    Label("Add Friend", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()

            Divider()

            if friends.isEmpty {
                Text("No friends yet 😢")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(friends, id: \.uid) { friend in
                        HStack {
                            Text(friend.username)
                            Spacer()
                            if isEditing {
                                Button {
                                    removeFriend(uid: friend.uid)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Friends")
        .navigationBarItems(trailing: Button(isEditing ? "Done" : "Edit") {
            isEditing.toggle()
        })
        .onAppear {
            loadRequests()
            loadFriends()
        }
        .sheet(isPresented: $showRequests) {
            NavigationView {
                FriendRequestsView()
                    .navigationTitle("Friend Requests")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showRequests = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showFriendSearch) {
            NavigationView {
                FriendSearchView()
                    .navigationTitle("Add Friend")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showFriendSearch = false
                            }
                        }
                    }
            }
        }
    }

    func loadRequests() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(myUID).addSnapshotListener { snapshot, _ in
            let requests = snapshot?.data()? ["friendRequests"] as? [String] ?? []
            requestCount = requests.count
        }
    }

    func loadFriends() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(myUID).getDocument { doc, _ in
            guard let data = doc?.data(), let friendUIDs = data["friends"] as? [String] else { return }

            var loadedFriends: [(String, String)] = []
            let group = DispatchGroup()

            for uid in friendUIDs {
                group.enter()
                db.collection("users").document(uid).getDocument { doc, _ in
                    let username = doc?.get("username") as? String ?? "Unknown"
                    loadedFriends.append((uid, username))
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.friends = loadedFriends
            }
        }
    }

    func removeFriend(uid: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let myRef = db.collection("users").document(myUID)
        let otherRef = db.collection("users").document(uid)

        myRef.updateData([
            "friends": FieldValue.arrayRemove([uid])
        ])

        otherRef.updateData([
            "friends": FieldValue.arrayRemove([myUID])
        ])

        friends.removeAll { $0.uid == uid }
    }
}
