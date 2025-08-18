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

        async let sentDocs = getDocuments(
            db.collection("recommendations").whereField("fromUID", isEqualTo: uid)
        )
        async let receivedDocs = getDocuments(
            db.collection("recommendations").whereField("toUID", isEqualTo: uid)
        )

        let (sent, received) = try await (sentDocs, receivedDocs)

        var sentUp = 0, sentDown = 0
        for doc in sent {
            if let vote = doc["vote"] as? Bool {
                vote ? (sentUp += 1) : (sentDown += 1)
            }
        }

        var receivedUp = 0, receivedDown = 0
        for doc in received {
            if let vote = doc["vote"] as? Bool {
                vote ? (receivedUp += 1) : (receivedDown += 1)
            }
        }

        return FriendStats(
            sentThumbsUp: sentUp,
            sentThumbsDown: sentDown,
            receivedThumbsUp: receivedUp,
            receivedThumbsDown: receivedDown
        )
    }

    static func fetchDetailedStats(for uid: String) async throws -> DetailedStats {
        let db = Firestore.firestore()

        async let sentDocs = getDocuments(
            db.collection("recommendations").whereField("fromUID", isEqualTo: uid)
        )
        async let receivedDocs = getDocuments(
            db.collection("recommendations").whereField("toUID", isEqualTo: uid)
        )

        let (sent, received) = try await (sentDocs, receivedDocs)

        var sentUp = 0, sentDown = 0, sentNoVote = 0
        for doc in sent {
            if let vote = doc["vote"] as? Bool {
                vote ? (sentUp += 1) : (sentDown += 1)
            } else {
                sentNoVote += 1
            }
        }

        var receivedUp = 0, receivedDown = 0, receivedNoVote = 0
        for doc in received {
            if let vote = doc["vote"] as? Bool {
                vote ? (receivedUp += 1) : (receivedDown += 1)
            } else {
                receivedNoVote += 1
            }
        }

        return DetailedStats(
            sentThumbsUp: sentUp,
            sentThumbsDown: sentDown,
            sentNoVote: sentNoVote,
            receivedThumbsUp: receivedUp,
            receivedThumbsDown: receivedDown,
            receivedNoVote: receivedNoVote
        )
    }
    
    enum StatChangeType {
        case increment
        case decrement
    }
    
    static func updateStatsInFirestore(for rec: Recommendation, change: StatChangeType) async throws {
        guard let vote = rec.vote,
              let _ = rec.id else { return }

        let fromUID = rec.fromUID
        let toUID = rec.toUID

        let db = Firestore.firestore()

        let changeValue = (change == .increment) ? Int64(1) : Int64(-1)
        let fromField = vote ? "sentThumbsUp" : "sentThumbsDown"
        let toField = vote ? "receivedThumbsUp" : "receivedThumbsDown"

        async let fromUpdate = setData(
            db.collection("users").document(fromUID),
            data: ["stats.\(fromField)": FieldValue.increment(changeValue)]
        )
        async let toUpdate = setData(
            db.collection("users").document(toUID),
            data: ["stats.\(toField)": FieldValue.increment(changeValue)]
        )

        try await fromUpdate
        try await toUpdate
    }

    private static func getDocuments(_ query: Query) async throws -> [QueryDocumentSnapshot] {
        try await withCheckedThrowingContinuation { continuation in
            query.getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: snapshot?.documents ?? [])
                }
            }
        }
    }

    private static func setData(_ ref: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            ref.setData(data, merge: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
