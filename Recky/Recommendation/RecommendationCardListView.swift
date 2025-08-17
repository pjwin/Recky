import SwiftUI
import FirebaseAuth

struct RecommendationCardListView: View {
    let recommendations: [Recommendation]
    let maxCount: Int?
    let onArchive: (Recommendation) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(recommendations.prefix(maxCount ?? recommendations.count)) { rec in
                let isSent = rec.fromUID == Auth.auth().currentUser?.uid

                NavigationLink(
                    destination: isSent
                        ? AnyView(SentRecommendationDetailView(recommendation: rec))
                        : AnyView(RecommendationDetailView(recommendation: rec))
                ) {
                    RecommendationCardView(recommendation: rec, isSent: isSent)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        onArchive(rec)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.gray)
                }
            }

        }
    }
}
