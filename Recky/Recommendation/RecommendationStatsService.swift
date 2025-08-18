import FirebaseFirestore
import FirebaseAuth

struct FriendStats {
    let sentThumbsUp: Int
    let sentThumbsDown: Int
    let receivedThumbsUp: Int
    let receivedThumbsDown: Int

    var sentTotal: Int { sentThumbsUp + sentThumbsDown }
    var receivedTotal: Int { receivedThumbsUp + receivedThumbsDown }

    var sentText: String {
        "\(sentThumbsUp)/\(sentTotal) (\(percentage(sentThumbsUp, of: sentTotal)))"
    }

    var receivedText: String {
        "\(receivedThumbsUp)/\(receivedTotal) (\(percentage(receivedThumbsUp, of: receivedTotal)))"
    }

    private func percentage(_ part: Int, of total: Int) -> String {
        guard total > 0 else { return "0%" }
        let percent = Int((Double(part) / Double(total)) * 100)
        return "\(percent)%"
    }
}

struct DetailedStats {
    let sentThumbsUp: Int
    let sentThumbsDown: Int
    let sentNoVote: Int
    let receivedThumbsUp: Int
    let receivedThumbsDown: Int
    let receivedNoVote: Int

    var sentTotal: Int {
        sentThumbsUp + sentThumbsDown + sentNoVote
    }

    var receivedTotal: Int {
        receivedThumbsUp + receivedThumbsDown + receivedNoVote
    }

    var sentUpPercentage: String { percent(sentThumbsUp, of: sentTotal) }
    var sentDownPercentage: String { percent(sentThumbsDown, of: sentTotal) }
    var receivedUpPercentage: String { percent(receivedThumbsUp, of: receivedTotal) }
    var receivedDownPercentage: String { percent(receivedThumbsDown, of: receivedTotal) }
    var sentNoVotePercentage: String {percent(sentNoVote, of: sentTotal)}
    var receivedNoVotePercentage: String {percent(receivedNoVote, of: receivedTotal)}

    private func percent(_ count: Int, of total: Int) -> String {
        guard total > 0 else { return "0%" }
        return "\(Int(round(Double(count) / Double(total) * 100)))%"
    }
}

class RecommendationStatsService {
    static func fetchStats(for uid: String) async throws -> FriendStats {
        let db = Firestore.firestore()
        let doc = try await getDocument(db.collection("users").document(uid))
        let stats = (doc.data()?["stats"] as? [String: Any]) ?? [:]
        let sentUp = stats["sentThumbsUp"] as? Int ?? 0
        let sentDown = stats["sentThumbsDown"] as? Int ?? 0
        let receivedUp = stats["receivedThumbsUp"] as? Int ?? 0
        let receivedDown = stats["receivedThumbsDown"] as? Int ?? 0

        return FriendStats(
            sentThumbsUp: sentUp,
            sentThumbsDown: sentDown,
            receivedThumbsUp: receivedUp,
            receivedThumbsDown: receivedDown
        )
    }

    static func fetchDetailedStats(for uid: String) async throws -> DetailedStats {
        let db = Firestore.firestore()
        let doc = try await getDocument(db.collection("users").document(uid))
        let stats = (doc.data()?["stats"] as? [String: Any]) ?? [:]
        let sentUp = stats["sentThumbsUp"] as? Int ?? 0
        let sentDown = stats["sentThumbsDown"] as? Int ?? 0
        let sentNoVote = stats["sentNoVote"] as? Int ?? 0
        let receivedUp = stats["receivedThumbsUp"] as? Int ?? 0
        let receivedDown = stats["receivedThumbsDown"] as? Int ?? 0
        let receivedNoVote = stats["receivedNoVote"] as? Int ?? 0

        return DetailedStats(
            sentThumbsUp: sentUp,
            sentThumbsDown: sentDown,
            sentNoVote: sentNoVote,
            receivedThumbsUp: receivedUp,
            receivedThumbsDown: receivedDown,
            receivedNoVote: receivedNoVote
        )
    }

    static func updateStatsInFirestore(
        for rec: Recommendation,
        previousVote: Bool?,
        newVote: Bool?
    ) async throws {
        let db = Firestore.firestore()
        try await runTransaction(db: db) { transaction in
            let fromRef = db.collection("users").document(rec.fromUID)
            let toRef = db.collection("users").document(rec.toUID)

            let fromUpdates = self.updates(forPrefix: "sent", previous: previousVote, new: newVote)
            let toUpdates = self.updates(forPrefix: "received", previous: previousVote, new: newVote)

            if !fromUpdates.isEmpty {
                transaction.updateData(fromUpdates, forDocument: fromRef)
            }
            if !toUpdates.isEmpty {
                transaction.updateData(toUpdates, forDocument: toRef)
            }
        }
    }

    private static func updates(
        forPrefix prefix: String,
        previous: Bool?,
        new: Bool?
    ) -> [String: Any] {
        var updates: [String: Any] = [:]
        let upField = "stats.\(prefix)ThumbsUp"
        let downField = "stats.\(prefix)ThumbsDown"
        let noneField = "stats.\(prefix)NoVote"

        switch (previous, new) {
        case (nil, nil):
            updates[noneField] = FieldValue.increment(Int64(1))
        case (nil, .some(let vote)):
            updates[noneField] = FieldValue.increment(Int64(-1))
            updates[vote ? upField : downField] = FieldValue.increment(Int64(1))
        case (.some(let prev), nil):
            updates[noneField] = FieldValue.increment(Int64(1))
            updates[prev ? upField : downField] = FieldValue.increment(Int64(-1))
        case (.some(let prev), .some(let next)):
            if prev != next {
                updates[prev ? upField : downField] = FieldValue.increment(Int64(-1))
                updates[next ? upField : downField] = FieldValue.increment(Int64(1))
            }
        }

        return updates
    }

    private static func getDocument(_ ref: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            ref.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    let err = NSError(domain: "RecommendationStatsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
                    continuation.resume(throwing: err)
                }
            }
        }
    }

    private static func runTransaction(
        db: Firestore,
        updateBlock: @escaping (Transaction) throws -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            db.runTransaction({ transaction, errorPointer -> Any? in
                do {
                    try updateBlock(transaction)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    // Cloud Function hooks could validate these updates server-side to ensure
    // stats cannot be manipulated by clients directly.
}
