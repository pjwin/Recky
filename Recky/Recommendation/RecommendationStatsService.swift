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
    static func fetchStats(for uid: String, completion: @escaping (FriendStats) -> Void) {
        let db = Firestore.firestore()
        var sentUp = 0, sentDown = 0
        var receivedUp = 0, receivedDown = 0
        let group = DispatchGroup()

        group.enter()
        db.collection("recommendations")
            .whereField("fromUID", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                for doc in snapshot?.documents ?? [] {
                    if let vote = doc["vote"] as? Bool {
                        vote ? (sentUp += 1) : (sentDown += 1)
                    }
                }
                group.leave()
            }

        group.enter()
        db.collection("recommendations")
            .whereField("toUID", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                for doc in snapshot?.documents ?? [] {
                    if let vote = doc["vote"] as? Bool {
                        vote ? (receivedUp += 1) : (receivedDown += 1)
                    }
                }
                group.leave()
            }

        group.notify(queue: .main) {
            completion(FriendStats(
                sentThumbsUp: sentUp,
                sentThumbsDown: sentDown,
                receivedThumbsUp: receivedUp,
                receivedThumbsDown: receivedDown
            ))
        }
    }
    
    static func fetchDetailedStats(for uid: String, completion: @escaping (DetailedStats) -> Void) {
        let db = Firestore.firestore()
        var sentUp = 0, sentDown = 0, sentNoVote = 0
        var receivedUp = 0, receivedDown = 0, receivedNoVote = 0
        let group = DispatchGroup()

        group.enter()
        db.collection("recommendations")
            .whereField("fromUID", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                for doc in snapshot?.documents ?? [] {
                    if let vote = doc["vote"] as? Bool {
                        vote ? (sentUp += 1) : (sentDown += 1)
                    } else {
                        sentNoVote += 1
                    }
                }
                group.leave()
            }

        group.enter()
        db.collection("recommendations")
            .whereField("toUID", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                for doc in snapshot?.documents ?? [] {
                    if let vote = doc["vote"] as? Bool {
                        vote ? (receivedUp += 1) : (receivedDown += 1)
                    } else {
                        receivedNoVote += 1
                    }
                }
                group.leave()
            }

        group.notify(queue: .main) {
            completion(DetailedStats(
                sentThumbsUp: sentUp,
                sentThumbsDown: sentDown,
                sentNoVote: sentNoVote,
                receivedThumbsUp: receivedUp,
                receivedThumbsDown: receivedDown,
                receivedNoVote: receivedNoVote
            ))
        }
    }
    
    enum StatChangeType {
        case increment
        case decrement
    }
    
    static func updateStatsInFirestore(for rec: Recommendation, change: StatChangeType) {
        guard let vote = rec.vote,
              let _ = rec.id else { return }

        let fromUID = rec.fromUID
        let toUID = rec.toUID

        let db = Firestore.firestore()

        let changeValue = (change == .increment) ? Int64(1) : Int64(-1)
        let fromField = vote ? "sentThumbsUp" : "sentThumbsDown"
        let toField = vote ? "receivedThumbsUp" : "receivedThumbsDown"

        db.collection("users").document(fromUID).setData([
            "stats.\(fromField)": FieldValue.increment(changeValue)
        ], merge: true)

        db.collection("users").document(toUID).setData([
            "stats.\(toField)": FieldValue.increment(changeValue)
        ], merge: true)
    }
}
