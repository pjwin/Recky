import FirebaseAuth
import FirebaseFirestore

class RecommendationService {
    static let shared = RecommendationService()
    private let db = Firestore.firestore()
    private init() {}

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
