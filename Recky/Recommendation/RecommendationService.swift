import FirebaseAuth
import FirebaseFirestore

class RecommendationService {
    static let shared = RecommendationService()
    private let db = Firestore.firestore()
    private init() {}

    func searchUsers(query: String, excludeUID: String, limit: Int = 5, completion: @escaping ([(uid: String, username: String)]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }

        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThan: query + "\u{f8ff}")
            .limit(to: limit)
            .getDocuments { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else {
                    print("Error searching users: \(error?.localizedDescription ?? "unknown error")")
                    completion([])
                    return
                }

                let results = documents.compactMap { doc -> (uid: String, username: String)? in
                    let uid = doc.documentID
                    guard uid != excludeUID else { return nil }
                    let username = doc.get("username") as? String ?? ""
                    return (uid: uid, username: username)
                }

                completion(results)
            }
    }

    func send(_ rec: Recommendation, completion: @escaping (Result<Void, Error>) -> Void) {
        var data: [String: Any] = [
            "fromUID": rec.fromUID,
            "fromUsername": rec.fromUsername ?? "",
            "toUID": rec.toUID,
            "toUsername": rec.toUsername ?? "",
            "title": rec.title,
            "type": rec.type,
            "timestamp": FieldValue.serverTimestamp(),
            "vote": NSNull()
        ]

        if let notes = rec.notes {
            data["notes"] = notes
        }

        db.collection("recommendations").addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
