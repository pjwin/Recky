import FirebaseFirestore
import FirebaseAuth

class RecommendationRepository {
    static let shared = RecommendationRepository()
    private let db = Firestore.firestore()
    private init() {}

    func fetchRecommendations(for uid: String) async throws -> [Recommendation] {
        async let sentSnapshot = db.collection("recommendations")
            .whereField("fromUID", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        async let receivedSnapshot = db.collection("recommendations")
            .whereField("toUID", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        let (sentDocs, receivedDocs) = try await (sentSnapshot, receivedSnapshot)
        let docs = sentDocs.documents + receivedDocs.documents
        let recs: [Recommendation] = docs.compactMap { doc in
            do {
                var rec = try doc.data(as: Recommendation.self)
                rec.id = doc.documentID
                rec.hasBeenViewedByRecipient = doc.get("hasBeenViewedByRecipient") as? Bool ?? false
                return rec
            } catch {
                print("Failed to parse recommendation: \(error)")
                return nil
            }
        }
        return recs
    }

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
        _ = try await db.collection("recommendations").addDocument(data: data)
    }

    func vote(recommendationID: String, vote: Bool?) async throws {
        let ref = db.collection("recommendations").document(recommendationID)
        if let vote = vote {
            try await ref.updateData(["vote": vote])
        } else {
            try await ref.updateData(["vote": FieldValue.delete()])
        }
    }

    func saveVoteNote(id: String, note: String) async throws {
        let ref = db.collection("recommendations").document(id)
        try await ref.updateData(["voteNote": note])
    }

    func archive(id: String, by uid: String) async throws {
        try await db.collection("recommendations").document(id)
            .updateData(["archivedBy": FieldValue.arrayUnion([uid])])
    }

    func markViewed(id: String) async throws {
        try await db.collection("recommendations").document(id)
            .updateData(["hasBeenViewedByRecipient": true])
    }
}

