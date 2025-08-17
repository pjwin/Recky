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

        let db = Firestore.firestore()

        do {
            // Fetch sent and received recommendations in parallel
            async let sentSnapshot = db.collection("recommendations")
                .whereField("fromUID", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .getDocuments()

            async let receivedSnapshot = db.collection("recommendations")
                .whereField("toUID", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .getDocuments()

            let (sentDocs, receivedDocs) = try await (sentSnapshot, receivedSnapshot)
            let combinedDocs = sentDocs.documents + receivedDocs.documents

            // Convert documents to Recommendation objects
            let recs: [Recommendation] = combinedDocs.compactMap { doc in
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

            self.allRecommendations = recs
            applySearch()
        } catch {
            print("Failed to fetch recommendations: \(error)")
        }

        loading = false
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
    
    @MainActor
    func archive(rec: Recommendation) {
        guard let uid = Auth.auth().currentUser?.uid,
              let id = rec.id else { return }

        Firestore.firestore().collection("recommendations").document(id)
            .updateData([
                "archivedBy": FieldValue.arrayUnion([uid])
            ]) { error in
                if let error = error {
                    print("Failed to archive recommendation: \(error)")
                } else {
                    Task { await self.fetchAllRecommendationsAsync() }
                }
            }
    }
}
