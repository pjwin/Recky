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
}
