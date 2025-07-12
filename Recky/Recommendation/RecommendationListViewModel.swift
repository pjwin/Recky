import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class RecommendationListViewModel: ObservableObject {
    @Published var allRecommendations: [Recommendation] = []
    @Published var filteredRecommendations: [Recommendation] = []
    @Published var showReceived = true
    @Published var showSent = true
    @Published var selectedType: String? = nil
    @Published var selectedUser: String? = nil
    @Published var loading = false
    @Published var titleQuery: String = ""

    private var myUID: String? {
        Auth.auth().currentUser?.uid
    }

    func fetchAllRecommendations() {
        Task {
            await fetchAllRecommendationsAsync()
        }
    }

    private func fetchAllRecommendationsAsync() async {
        guard let uid = myUID else { return }
        loading = true

        var results = [Recommendation]()

        do {
            let snapshot = try await Firestore.firestore()
                .collection("recommendations")
                .order(by: "timestamp", descending: true)
                .getDocuments()

            for doc in snapshot.documents {
                do {
                    var rec = try doc.data(as: Recommendation.self)
                    rec.id = doc.documentID
                    rec.hasBeenViewedByRecipient = doc.get("hasBeenViewedByRecipient") as? Bool ?? false

                    let isSent = rec.fromUID == uid
                    let userID = isSent ? rec.toUID : rec.fromUID
                    let usernameKey = isSent ? "toUsername" : "fromUsername"

                    do {
                        let userDoc = try await Firestore.firestore().collection("users").document(userID).getDocument()
                        let username = userDoc.get("username") as? String ?? "unknown"
                        if usernameKey == "fromUsername" {
                            rec.fromUsername = username
                        } else {
                            rec.toUsername = username
                        }
                    } catch {
                        print("Failed to fetch user \(userID): \(error)")
                    }

                    results.append(rec)

                } catch {
                    print("Failed to parse recommendation: \(error)")
                }
            }

            self.allRecommendations = results
            applySearch()
        } catch {
            print("Failed to fetch recommendations: \(error)")
        }

        loading = false
    }


    private func processRecommendation(
        from doc: QueryDocumentSnapshot,
        currentUID uid: String
    ) async -> Recommendation? {
        guard var rec = try? doc.data(as: Recommendation.self) else {
            return nil
        }

        rec.id = doc.documentID
        rec.hasBeenViewedByRecipient =
            doc.get("hasBeenViewedByRecipient") as? Bool ?? false

        let isSent = rec.fromUID == uid
        let userID = isSent ? rec.toUID : rec.fromUID
        let usernameKey = isSent ? "toUsername" : "fromUsername"

        do {
            let userDoc = try await Firestore.firestore()
                .collection("users")
                .document(userID)
                .getDocument()

            let username = userDoc.get("username") as? String ?? "unknown"
            if usernameKey == "fromUsername" {
                rec.fromUsername = username
            } else {
                rec.toUsername = username
            }
        } catch {
            print("Error fetching username for \(userID): \(error)")
        }

        return rec
    }

    func applySearch() {
        guard let uid = myUID else { return }

        filteredRecommendations = allRecommendations.filter { rec in
            let isSent = rec.fromUID == uid
            let isReceived = rec.toUID == uid

            let directionAllowed =
                (isSent && showSent) || (isReceived && showReceived)
            let matchesType =
                selectedType == nil
                || rec.type.lowercased() == selectedType?.lowercased()
            let matchesUser =
                selectedUser == nil
                || (isSent
                    && rec.toUsername?.lowercased().contains(
                        selectedUser!.lowercased()
                    ) == true)
                || (isReceived
                    && rec.fromUsername?.lowercased().contains(
                        selectedUser!.lowercased()
                    ) == true)
            let matchesTitle =
                titleQuery.isEmpty
                || rec.title.lowercased().contains(titleQuery.lowercased())

            return directionAllowed && matchesType && matchesUser
                && matchesTitle
        }
    }

    func resetSearch() {
        showReceived = true
        showSent = true
        selectedType = nil
        selectedUser = nil
        titleQuery = ""
        applySearch()
    }
}
