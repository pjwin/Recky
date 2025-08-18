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

        guard let data = doc.data(),
              let rawRequests = data["friendRequests"] as? [[String: Any]] else {
            return []
        }

        let requests: [(uid: String, username: String)] = rawRequests.compactMap { map in
            guard let uid = map["uid"] as? String,
                  let username = map["username"] as? String else {
                return nil
            }
            return (uid, username)
        }

        return requests
    }

    func fetchFriends(for uid: String) async throws -> [Friend] {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("users").document(uid).collection("friends").getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let docs = snapshot?.documents ?? []
                let friends = docs.map { doc in
                    Friend(id: doc.documentID, username: doc.get("username") as? String ?? "Unknown")
                }
                continuation.resume(returning: friends)
            }
        }
    }

    func sendFriendRequestByEmail(_ email: String, from currentUID: String) async throws -> String {
        let emailLower = email.lowercased()
        let snapshot = try await withCheckedThrowingContinuation { continuation in
            db.collection("users")
                .whereField("emailLowercase", isEqualTo: emailLower)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: snapshot)
                    }
                }
        }

        guard let doc = snapshot.documents.first else {
            return "If the email is registered, your request has been sent."
        }

        let targetUID = doc.documentID
        if targetUID == currentUID {
            return "You can't send a friend request to yourself."
        }

        let myRef = db.collection("users").document(currentUID)
        let targetRef = db.collection("users").document(targetUID)

        let mySnap = try await getDocument(myRef)
        let myUsername = mySnap.get("username") as? String ?? "Unknown"

        try await updateDocument(myRef, data: [
            "sentRequests": FieldValue.arrayUnion([targetUID])
        ])
        try await updateDocument(targetRef, data: [
            "friendRequests": FieldValue.arrayUnion([["uid": currentUID, "username": myUsername]])
        ])

        return "That user will receive your friend request if they are registered."
    }

    func acceptRequest(from otherUID: String, otherUsername: String, currentUID: String) async throws {
        let myRef = db.collection("users").document(currentUID)
        let otherRef = db.collection("users").document(otherUID)

        let otherSnap = try await getDocument(otherRef)
        let senderUsername = otherSnap.get("username") as? String ?? ""

        let mySnap = try await getDocument(myRef)
        let myUsername = mySnap.get("username") as? String ?? "Unknown"

        try await updateDocument(myRef, data: [
            "friendRequests": FieldValue.arrayRemove([["uid": otherUID, "username": otherUsername]])
        ])
        try await updateDocument(otherRef, data: [
            "sentRequests": FieldValue.arrayRemove([currentUID])
        ])

        try await setDocument(myRef.collection("friends").document(otherUID), data: [
            "username": senderUsername,
            "addedAt": FieldValue.serverTimestamp()
        ])
        try await setDocument(otherRef.collection("friends").document(currentUID), data: [
            "username": myUsername,
            "addedAt": FieldValue.serverTimestamp()
        ])
    }

    func ignoreRequest(from otherUID: String, otherUsername: String, currentUID: String) async throws {
        try await updateDocument(db.collection("users").document(currentUID), data: [
            "friendRequests": FieldValue.arrayRemove([["uid": otherUID, "username": otherUsername]])
        ])
    }

    func removeFriend(_ uid: String, currentUID: String) async throws {
        let myRef = db.collection("users").document(currentUID).collection("friends").document(uid)
        let otherRef = db.collection("users").document(uid).collection("friends").document(currentUID)

        try await deleteDocument(myRef)
        try await deleteDocument(otherRef)
    }

    private func getDocument(_ ref: DocumentReference) async throws -> DocumentSnapshot {
        return try await withCheckedThrowingContinuation { continuation in
            ref.getDocument { snapshot, error in
                if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "FriendService", code: -1))
                }
            }
        }
    }

    private func updateDocument(_ ref: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            ref.updateData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func setDocument(_ ref: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            ref.setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func deleteDocument(_ ref: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { continuation in
            ref.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
