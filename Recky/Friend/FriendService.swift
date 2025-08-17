import FirebaseFirestore

class FriendService {
    static let shared = FriendService()
    private let db = Firestore.firestore()
    private init() {}

    func searchFriends(query: String, currentUID: String, limit: Int = 5, completion: @escaping ([(uid: String, username: String)]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }

        db.collection("users")
            .document(currentUID)
            .collection("friends")
            .order(by: "username")
            .start(at: [query])
            .end(at: [query + "\u{f8ff}"])
            .limit(to: limit)
            .getDocuments { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else {
                    print("Error searching friends: \(error?.localizedDescription ?? "unknown error")")
                    completion([])
                    return
                }

                let results = documents.compactMap { doc -> (uid: String, username: String)? in
                    let uid = doc.documentID
                    let username = doc.get("username") as? String ?? ""
                    return (uid, username)
                }

                completion(results)
            }
    }

    func fetchFriendRequests(for uid: String, completion: @escaping ([(uid: String, username: String)]) -> Void) {
        db.collection("users").document(uid).getDocument { doc, _ in
            guard let data = doc?.data(),
                  let ids = data["friendRequests"] as? [String] else {
                completion([])
                return
            }

            var results: [(uid: String, username: String)] = []
            let group = DispatchGroup()
            for id in ids {
                group.enter()
                self.db.collection("users").document(id).getDocument { snap, _ in
                    if let username = snap?.get("username") as? String {
                        results.append((id, username))
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion(results)
            }
        }
    }

    func acceptRequest(from otherUID: String, currentUID: String, completion: @escaping () -> Void) {
        let myRef = db.collection("users").document(currentUID)
        let otherRef = db.collection("users").document(otherUID)

        otherRef.getDocument { snapshot, _ in
            guard let data = snapshot?.data(),
                  let otherUsername = data["username"] as? String else {
                completion()
                return
            }

            myRef.getDocument { mySnap, _ in
                let myUsername = mySnap?.get("username") as? String ?? "Unknown"

                myRef.updateData([
                    "friendRequests": FieldValue.arrayRemove([otherUID])
                ])
                otherRef.updateData([
                    "sentRequests": FieldValue.arrayRemove([currentUID])
                ])

                myRef.collection("friends").document(otherUID).setData([
                    "username": otherUsername,
                    "addedAt": FieldValue.serverTimestamp()
                ])
                otherRef.collection("friends").document(currentUID).setData([
                    "username": myUsername,
                    "addedAt": FieldValue.serverTimestamp()
                ])

                completion()
            }
        }
    }

    func ignoreRequest(from otherUID: String, currentUID: String, completion: (() -> Void)? = nil) {
        db.collection("users").document(currentUID).updateData([
            "friendRequests": FieldValue.arrayRemove([otherUID])
        ]) { _ in
            completion?()
        }
    }

    func sendFriendRequestByEmail(_ email: String, from currentUID: String, completion: @escaping (String) -> Void) {
        let emailLower = email.lowercased()
        db.collection("users")
            .whereField("emailLowercase", isEqualTo: emailLower)
            .getDocuments { snapshot, _ in
                guard let doc = snapshot?.documents.first else {
                    completion("If the email is registered, your request has been sent.")
                    return
                }

                let targetUID = doc.documentID
                if targetUID == currentUID {
                    completion("You can't send a friend request to yourself.")
                    return
                }

                let myRef = self.db.collection("users").document(currentUID)
                let targetRef = self.db.collection("users").document(targetUID)
                myRef.updateData([
                    "sentRequests": FieldValue.arrayUnion([targetUID])
                ])
                targetRef.updateData([
                    "friendRequests": FieldValue.arrayUnion([currentUID])
                ])

                completion("That user will receive your friend request if they are registered.")
            }
    }
}
