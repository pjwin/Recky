import FirebaseAuth
import FirebaseFirestore

class RecommendationService {
    static let shared = RecommendationService()
    private let db = Firestore.firestore()
    private init() {}

    func send(_ rec: Recommendation) async throws {
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

        try await withCheckedThrowingContinuation { continuation in
            db.collection("recommendations").addDocument(data: data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        try await RecommendationStatsService.updateStatsInFirestore(
            for: rec,
            previousVote: nil,
            newVote: nil
        )
    }
}
