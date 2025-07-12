import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendRequestsView: View {
    @State private var requests: [(uid: String, username: String)] = []

    var onFriendAccepted: () -> Void = {}

    var body: some View {
        VStack {
            List(requests, id: \.uid) { request in
                VStack(spacing: 8) {
                    Text(request.username)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 24) {
                        Button("Accept") {
                            acceptRequest(from: request.uid)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button("Ignore") {
                            ignoreRequest(fromUID: request.uid)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                .padding(.horizontal)
            }
        }
        .onAppear(perform: loadRequests)
    }

    func loadRequests() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(myUID).getDocument { doc, error in
            guard let data = doc?.data(),
                let ids = data["friendRequests"] as? [String]
            else { return }
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

        // Fetch other user's username
        otherRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let otherUsername = data["username"] as? String else { return }

            // Fetch my username
            myRef.getDocument { mySnap, _ in
                let myUsername = mySnap?.get("username") as? String ?? "Unknown"

                // Remove friend requests
                myRef.updateData([
                    "friendRequests": FieldValue.arrayRemove([otherUID])
                ])
                otherRef.updateData([
                    "sentRequests": FieldValue.arrayRemove([myUID])
                ])

                // Add each other to friends subcollections
                myRef.collection("friends").document(otherUID).setData([
                    "username": otherUsername,
                    "addedAt": FieldValue.serverTimestamp()
                ])
                otherRef.collection("friends").document(myUID).setData([
                    "username": myUsername,
                    "addedAt": FieldValue.serverTimestamp()
                ])

                // Refresh view
                loadRequests()
            }
        }
    }



    func ignoreRequest(fromUID: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(myUID)
            .updateData([
                "friendRequests": FieldValue.arrayRemove([fromUID])
            ])
    }
}
