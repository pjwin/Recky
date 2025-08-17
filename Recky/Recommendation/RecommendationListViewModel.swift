import FirebaseAuth
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

        do {
            let recs = try await RecommendationRepository.shared
                .fetchRecommendations(for: uid)
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

        Task {
            do {
                try await RecommendationRepository.shared.archive(id: id, by: uid)
                await fetchAllRecommendationsAsync()
            } catch {
                print("Failed to archive recommendation: \(error)")
            }
        }
    }
}
