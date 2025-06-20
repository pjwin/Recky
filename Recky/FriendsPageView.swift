//
//  FriendsPageView.swift
//  Recky
//
//  Created by Paul Winters on 6/18/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendsPageView: View {
    @State private var friends: [(uid: String, username: String)] = []
    @State private var requestCount = 0
    @State private var showRequests = false
    @State private var showFriendSearch = false
    @State private var isEditing = false
    @State private var refreshTrigger = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: { showRequests = true }) {
                    HStack(spacing: 4) {
                        Label(
                            "Requests",
                            systemImage: "person.crop.circle.badge.questionmark"
                        )
                        if requestCount > 0 {
                            Text("(\(requestCount))")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(action: { showFriendSearch = true }) {
                    Label("Add Friend", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()

            Divider()

            List {
                if friends.isEmpty {
                    Text("No friends yet �")
                        .foregroundColor(.gray)
                } else {
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
            }
        )
        .onAppear {
            loadRequests()
            loadFriends()
        }
        .onChange(of: refreshTrigger) {
            loadFriends()
        }
        .sheet(isPresented: $showRequests) {
            NavigationView {
                FriendRequestsView(onFriendAccepted: {
                    refreshTrigger.toggle()
                })
                .navigationTitle("Friend Requests")
                .navigationBarTitleDisplayMode(.inline)
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
                    .navigationBarTitleDisplayMode(.inline)
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
        db.collection("users").document(myUID).addSnapshotListener {
            snapshot,
            _ in
            let requests =
                snapshot?.data()?["friendRequests"] as? [String] ?? []
            requestCount = requests.count
        }
    }

    func loadFriends() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(myUID).getDocument { doc, _ in
            guard let data = doc?.data(),
                let friendUIDs = data["friends"] as? [String]
            else { return }

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
