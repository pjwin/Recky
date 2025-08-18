import FirebaseFirestore

class FriendService {
    static let shared = FriendService()
    private let db = Firestore.firestore()
    private init() {}

    func searchFriends(query: String, currentUID: String, limit: Int = 5) async throws -> [(uid: String, username: String)] {
        guard !query.isEmpty else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            db.collection("users")
                .document(currentUID)
                .collection("friends")
                .order(by: "username")
                .start(at: [query])
                .end(at: [query + "\u{f8ff}"])
                .limit(to: limit)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let documents = snapshot?.documents ?? []

                    let results = documents.compactMap { doc -> (uid: String, username: String)? in
                        let uid = doc.documentID
                        let username = doc.get("username") as? String ?? ""
                        return (uid, username)
                    }
                    continuation.resume(returning: results)
                }
        }
    }

    func fetchFriendRequests(for uid: String) async throws -> [(uid: String, username: String)] {
        let doc = try await withCheckedThrowingContinuation { continuation in
            db.collection("users").document(uid).getDocument { doc, error in
                if let doc = doc {
                    continuation.resume(returning: doc)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "FriendService", code: -1))
                }
            }
        }

        guard let data = doc.data(), let ids = data["friendRequests"] as? [String] else {
            return []
        }

        return try await withThrowingTaskGroup(of: (String, String)?.self, returning: [(uid: String, username: String)].self) { group in
            for id in ids {
                group.addTask {
                    try await withCheckedThrowingContinuation { continuation in
                        self.db.collection("users").document(id).getDocument { snap, error in
                            if let username = snap?.get("username") as? String {
                                continuation.resume(returning: (id, username))
                            } else if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        }
                    }
                }
            }

            var results: [(uid: String, username: String)] = []
            for try await result in group {
                if let r = result {
                    results.append(r)
                }
            }
            return results
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
